module PollHeadTestM
{
	provides interface StdControl;
	  uses
	{
		interface SplitControl as MACControl;
		interface PollHeadComm;
		interface Leds;
		interface Timer as TimeoutTimer;
		interface Timer as SampleTimer;
		interface PrecisionTimer as PTimer;
		interface PrecisionTimer as PSampleTimer;
		interface PrecisionTimer as PTestTimer;
		interface StdControl as PTimerControl;
		interface Random;
		//interface PrecisionTimer as TimeoutTimer;
	}
}

implementation
{
#include "PollMsg.h"
#include "config.h"

#define FLAG_ACCESSED	0x02

	enum
	{
		STATUS_OK,
		STATUS_FAIL
	};
	typedef struct
	{
		uint16_t nodeId;
		uint8_t status;
		uint32_t fail_count;
		uint8_t retries;
		uint8_t flags;
	} Node;

	Node nodes[NUM_NODES];
	AppPkt pkt;
	AppPkt *pPkt;
	norace uint8_t node_id;
	uint32_t sample_start_ts;
	uint32_t node_req_ts;
	uint32_t good_data;
	uint32_t data_reqs;
	uint8_t new_sample;
	uint32_t nodes_left;
	uint32_t avg_rtt;

	/*
	 * Dedicated task to request data from the current node_id.
	 */
	task void pollnodes()
	{
		//trace(DBG_USR1, "Requesting data from node %d, %d\r\n", node_id, call Random.rand() % nodes_left);
		//call TimeoutTimer.start(TIMER_ONE_SHOT, TIMEOUT_MS);
		atomic++ data_reqs;
		atomic nodes[node_id].status = STATUS_OK;
		/* Get current timestamp to find the RTT */
		atomic node_req_ts = call PTimer.getTime32();
		call PTimer.setAlarm(node_req_ts +
				     (uint32_t) TIMEOUT_JIFFIES);
		/* Set the timeout alarm */
		//call PTimer.setAlarm(node_req_ts + (uint32_t)TIMEOUT_JIFFIES);
		/* Request the data from node_id */
		if ((call PollHeadComm.
		     requestData(node_id, &pkt, sizeof(pkt))) == FAIL) {
		} else {
			atomic {
				//node_req_ts = call PTimer.getTime32();
				//call PTimer.setAlarm(node_req_ts + (uint32_t)TIMEOUT_JIFFIES);
			}
		}
	}

	inline uint8_t check_enough_time()
	{
		uint32_t jiffies_left;
		uint8_t enough_time = 1;

		atomic {
			jiffies_left = SAMPLE_INTERVAL_JIFFIES -
			    (call PTimer.getTime32() - sample_start_ts);
			if (jiffies_left < avg_rtt) {
				enough_time = 0;
				//trace(DBG_USR1, "jiffes_left (%d) < avg_rtt (%d)\r\n", jiffies_left, avg_rtt);
			}
		}

		return enough_time;
	}

	inline void poll_next_node()
	{
		uint8_t i, j;
		int8_t rand_no;

		atomic {
			nodes[node_id].retries = 0;
		}

		if (check_enough_time() == 0) {
			atomic {
#if POLL_RANDOM_ORDER == 1
				node_id = call Random.rand() % NUM_NODES;
#else
				node_id = 0;
#endif
			}
			return;
		}
#if POLL_RANDOM_ORDER == 1
		//trace(DBG_USR1, "Hey ho, poll_next_node, POLL_RANDOM_ORDER!\r\n");
		atomic {
			//nodes[node_id].retries = 0;
			nodes[node_id].flags |= FLAG_ACCESSED;
			--nodes_left;
			if (nodes_left == 0) {
				node_id = call Random.rand() % NUM_NODES;
			} else if (nodes_left == 1) {
				for (i = 0; i < NUM_NODES; i++) {
					if (nodes[i].flags & FLAG_ACCESSED)
						continue;
					node_id = i;
					post pollnodes();
					break;
				}
			} else {
				i = 0;	/* j = 10; */
				rand_no = call Random.rand() % nodes_left;
				while ((rand_no >= 0) /* && (j-- > 0) */ ) {
					//trace (DBG_USR1, "while... rand_no=%d, i=%d\r\n", rand_no, i);
					if (!(nodes[i].flags & FLAG_ACCESSED))
						--rand_no;
					if (rand_no >= 0)
						i++;
				}

				//trace(DBG_USR1, "post pollnodes(%d)\r\n", i);
				node_id = i;
				post pollnodes();
			}
		}
#else
		//trace(DBG_USR1, "non-random-order polling\r\n");
		atomic {
			//nodes[node_id].retries = 0;
			if (node_id == (NUM_NODES - 1)) {
				node_id = 0;
			} else {
				node_id++;
				post pollnodes();
			}
		}
#endif
	}


	event result_t PollHeadComm.requestDataDone(uint8_t id, void *data,
						    uint8_t err)
	{
		uint32_t node_ready_ts;
		float rtt_ms, std_ms;

		node_ready_ts = call PTimer.getTime32();

		/* Node answered after the request was failed / timed out */
		if (nodes[id].status == STATUS_FAIL) {
			//trace(DBG_USR1, "to,%d\r\n", id);
			//trace(DBG_USR1, "Node %d took too long to respond\r\n", id);
			return SUCCESS;
		}

		/*
		 * If the data is from a different id but not timeout happened,
		 * so it's likely that a new sampling period started and the
		 * previous one was full to the brim.
		 */
		if ((id != node_id) && (!err)) {
			pPkt = data;
			trace(DBG_USR1, "2,%d,%d,%d\r\n", id, node_id,
			      *((uint32_t *) pPkt->data));
			//trace(DBG_USR1, "It's likely that the sample period expired, node %d sent OOB message (node_id=%d)\r\n", id, node_id);
			return SUCCESS;
		}
		//call TimeoutTimer.stop();
		/* Unset the Timeout as we've received the packet already */
		call PTimer.clearAlarm();

		/*
		 * If the an error occured while receiving the data, increase
		 * the count of failures of the given note.
		 */
		if (err) {
			//trace(DBG_USR1, "error while requesting data... id=%d, node_id=%d\r\n", id, node_id);
			nodes[node_id].fail_count++;
		} else {
			/*
			 * If everything went well, calculated the round trip
			 * time (RTT) and sample to data time (STD, S2RT).
			 */
			atomic {
				/* Moving averager, ((n-1)*avg_{n-1} + x) / n */
				avg_rtt =
				    ((avg_rtt * good_data) +
				     (node_ready_ts -
				      node_req_ts)) / (good_data + 1);
			}

			atomic rtt_ms =
			    (node_ready_ts - node_req_ts -
			     0.0) / JIFFIES_PER_MS_F;
			atomic std_ms =
			    (node_ready_ts - sample_start_ts -
			     0.0) / JIFFIES_PER_MS_F;
			pPkt = data;
			/*
			 * Format:
			 * 3,<node_id>,<seq_id>,<RTT>,<S2DT>,<retry_count>,<fail_count>
			 */
			atomic++ good_data;
			trace(DBG_USR1, "3,%d,%d,%f,%f,%d,%d\r\n", id,
			      *((uint32_t *) pPkt->data), rtt_ms, std_ms,
			      nodes[id].retries, nodes[id].fail_count);
			//trace(DBG_USR1, "received data (from node %d) = %d,%d - RTT: %f ms (jiffies: %d), S2RT: %f ms\r\n", id, pPkt->data[0], pPkt->data[1], rtt_ms, node_ready_ts - node_req_ts, std_ms);
			call Leds.greenToggle();
			nodes[id].retries = 0;
		}
		/*
		 * If this is the last node, we just stop here and reset the
		 * node_id to the first one. The sample timer firing will start
		 * the whole process again.
		 * If this is not the last node, we move on to the next node and
		 * post the task to request data from it.
		 */
		//trace(DBG_USR1, "calling poll_next_node\r\n");
		poll_next_node();
#if 0
		atomic {
			nodes[node_id].retries = 0;
			if (node_id == (NUM_NODES - 1)) {
				node_id = 0;
			} else {
				node_id++;
				//trace(DBG_USR1, "special marker (1) for pollnodes(), node_id = %d\r\n", node_id);
				post pollnodes();
			}
		}
#endif
		return SUCCESS;
	}

	/*
	 * The precision timeout timer has fired, so call the timeout handler.
	 */
	async event result_t PTimer.alarmFired(uint32_t val)
	{
		int ret = 0;
		atomic {
			if (new_sample) {
				new_sample = 0;
				sample_start_ts = call PTimer.getTime32();
				post pollnodes();
				ret = 1;
			}
		}
		if (ret) {
			return SUCCESS;
			/* NOTREACHED */
		}

		signal TimeoutTimer.fired();
		return SUCCESS;
	}

	/*
	 * This is the timeout handler. It basically cancels the current request
	 * and goes on with the next one as described previously.
	 */
	event result_t TimeoutTimer.fired()
	{
		uint32_t cur_ts;

		atomic {
			cur_ts = call PTimer.getTime32();
		}
		trace(DBG_USR1, "4,%d\r\n", node_id);

		atomic {
			/* Cancel the current request. */
			call PollHeadComm.cancelRequest();
			nodes[node_id].status = STATUS_FAIL;
			nodes[node_id].fail_count++;
			if (nodes[node_id].retries < POLL_MAX_RETRIES) {
				atomic++ nodes[node_id].retries;
				if (check_enough_time() == 1) {
					post pollnodes();
				} else {
					atomic nodes[node_id].retries = 0;
				}
			} else {
				poll_next_node();
#if 0
				nodes[node_id].retries = 0;
				if (node_id == (NUM_NODES - 1)) {
					node_id = 0;
				} else {
					node_id++;
					//trace(DBG_USR1, "special marker (2) for pollnodes(), node_id = %d\r\n", node_id);
					post pollnodes();
				}
#endif
			}
		}
		return SUCCESS;
	}

	/*
	 * The sample timer fired, so a new sampling period has started.
	 * Send the sample start packet.
	 */
	event result_t SampleTimer.fired()
	{
#if 0
		//trace(DBG_USR1, "SampleTimer fired!!!!!!!!!!!!!!!!!!!\r\n");
		//call TimeoutTimer.stop();
		call PTimer.clearAlarm();
		call Leds.redToggle();
		atomic {
			node_id = 0;
		}
		//trace(DBG_USR1, "special marker (3) for pollnodes(), node_id = %d\r\n", node_id);
		//call PollHeadComm.sendSampleStart();
		signal PollHeadComm.sendSampleStartDone();
		//atomic sample_start_ts = call PTimer.getTime32();
		//post pollnodes();
		return SUCCESS;
#endif
		return SUCCESS;
	}

	async event result_t PTestTimer.alarmFired(uint32_t val)
	{
		atomic {
			call PollHeadComm.cancelRequest();
			call PSampleTimer.clearAlarm();
			call PTimer.clearAlarm();
		}
		trace(DBG_USR1, "F,%d,%d\r\n", good_data, data_reqs);
		return SUCCESS;
	}

	task void setSampleTimer()
	{
		uint32_t local_ts;
		uint8_t i;

		call PollHeadComm.cancelRequest();
		call PTimer.clearAlarm();
		call Leds.redToggle();

		local_ts = call PTimer.getTime32();
		call PSampleTimer.setAlarm(local_ts +
					   SAMPLE_INTERVAL_JIFFIES);

#if POLL_RANDOM_ORDER == 1
		//trace(DBG_USR1, "setSampleTimer: random order\r\n");
		atomic {
			for (i = 0; i < NUM_NODES; i++) {
				nodes[i].flags &= (~FLAG_ACCESSED);
			}
			nodes_left = NUM_NODES;
		}
#endif
		signal PollHeadComm.sendSampleStartDone();
		//call PollHeadComm.sendSampleStart();
		//trace(DBG_USR1, "cnt,%d\r\n", good_data);
	}

	async event result_t PSampleTimer.alarmFired(uint32_t val)
	{
		post setSampleTimer();
		return SUCCESS;
	}

	/*
	 * The sample start packet has been successfully sent. Save the start
	 * timestamp and start polling the first node.
	 */
	event result_t PollHeadComm.sendSampleStartDone()
	{
		atomic sample_start_ts = call PTimer.getTime32();
		nodes[node_id].retries = 0;
		atomic new_sample = 1;
		call PTimer.setAlarm(sample_start_ts + 20000);	/* approx 3 ms */
		//post pollnodes();
		return SUCCESS;
	}

	/*
	 * Initialize the leds, node id and precision timer.
	 */
	command result_t StdControl.init()
	{
		call Leds.init();
		call Random.init();
		call PTimerControl.init();
		return SUCCESS;
	}

	/*
	 * Mac initialization is done, now start the startup process.
	 */
	event result_t MACControl.initDone()
	{
		call MACControl.start();
		return SUCCESS;
	}

	/*
	 * Mac has finished startup. Let's start the sampling timer and set the
	 * beacon information (setSleepInterval).
	 */
	event result_t MACControl.startDone()
	{
		uint8_t i;
		uint32_t local_ts;
		atomic {
			for (i = 0; i < NUM_NODES; i++) {
				nodes[i].status = STATUS_OK;
				nodes[i].fail_count = 0;
				nodes[i].flags = 0;
			}
		}
		/* XXX: do actual work starting here */
		atomic node_id = 0;
		//call SampleTimer.start(TIMER_REPEAT, SAMPLE_INTERVAL_MS);
		call PollHeadComm.setSleepInterval(SLEEP_INTERVAL_MS *
						   JIFFIES_PER_MS);
		post setSampleTimer();
		local_ts = call PTimer.getTime32();
		call PTestTimer.setAlarm(local_ts +
					 JIFFIES_PER_MS * (TEST_TIME));
		return SUCCESS;
	}

	event result_t MACControl.stopDone()
	{
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		trace(DBG_USR1, "1,%d\r\n", NUM_NODES);
		call MACControl.init();
		return SUCCESS;
	}


	command result_t StdControl.stop()
	{
		call MACControl.stop();
	}





}				// end of implementation
