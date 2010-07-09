module CSMAHeadTestM
{
   provides interface StdControl;
   uses {
		interface SplitControl as PhyControl;
		interface PhyState;
		interface PhyComm;
		interface BackoffControl;
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
#include "CSMAMsg.h"
#include "config.h"

#define FLAG_ACCESSED	0x02

	enum {
		STATUS_OK,
		STATUS_FAIL
	};
	typedef struct {
		uint16_t nodeId;
		uint8_t status;
		uint32_t fail_count;
		uint8_t	retries;
		uint8_t flags;
	} Node;

	CSMAPkt pkt;
	CSMAPkt *pPkt;
	norace uint8_t node_id;
	uint32_t sample_start_ts;
	uint32_t node_req_ts;
	uint32_t good_data;
	uint32_t data_reqs;
	uint8_t new_sample;
	uint8_t test_finished;
	uint32_t nodes_left;
	uint32_t bad_data;

	uint32_t sample_interval;


	event result_t PhyComm.txPktDone(void *msg, uint8_t err)
	{
		return SUCCESS;
	}

	event result_t PhyComm.startSymDetected(void* foo)
	{
		//trace(DBG_USR1, "startsymdetect\r\n");
		return SUCCESS;
	}

	event void * PhyComm.rxPktDone(void *data, uint8_t err)
	{
		uint32_t node_ready_ts;
		float rtt_ms, std_ms;
		uint16_t id;
		uint32_t loc_sample_interval, loc_recv_intv;

		//call TimeoutTimer.stop();
		/* Unset the Timeout as we've received the packet already */
		node_ready_ts = call PTimer.getTime32();
		atomic loc_sample_interval = sample_interval;
		call PTimer.clearAlarm();

		/*
		 * If the an error occured while receiving the data, increase
		 * the count of failures of the given note.
		 */
		if (err)
			atomic ++bad_data;

		if (err || test_finished) {
			//trace(DBG_USR1, "error while requesting data... id=%d, node_id=%d\r\n", id, node_id);
		} else {
			/*
			 * If everything went well, calculated the round trip
			 * time (RTT) and sample to data time (STD, S2RT).
			 */
			atomic std_ms = (node_ready_ts - sample_start_ts - 0.0)/JIFFIES_PER_MS_F;
			pPkt = (CSMAPkt *)data;
			if (pPkt->hdr.type != CSMA_DATA)
				return data;
			/*
			 * Format:
			 * 3,<node_id>,<seq_id>,<RTT>,<S2DT>,<retry_count>,<fail_count>
			 */
			atomic ++good_data;
			id = pPkt->hdr.src_id;
			loc_recv_intv = pPkt->hdr.sample_interval;

			if (loc_recv_intv != loc_sample_interval) {
				trace(DBG_USR1, "2,%d,%d,%d,%d\r\n", id, *((uint32_t *)pPkt->data), loc_recv_intv, loc_sample_interval);
			} else {
				trace(DBG_USR1, "3,%d,%d,%f\r\n", id, *((uint32_t *)pPkt->data), std_ms);
				call Leds.greenToggle();
			}
		}
		return data;
	}

	/*
	 * The precision timeout timer has fired, so call the timeout handler.
	 */
	async event result_t PTimer.alarmFired(uint32_t val)
	{
		return SUCCESS;
	}

	/*
	 * This is the timeout handler. It basically cancels the current request
	 * and goes on with the next one as described previously.
	 */
	event result_t TimeoutTimer.fired()
	{
		return SUCCESS;
	}

	/*
	 * The sample timer fired, so a new sampling period has started.
	 * Send the sample start packet.
	 */
   	event result_t SampleTimer.fired()
	{
		return SUCCESS;
	}

	async event result_t PTestTimer.alarmFired(uint32_t val)
	{
		atomic {
			call PSampleTimer.clearAlarm();
			call PTimer.clearAlarm();
			call Leds.yellowOff();
			test_finished = 1;
		}
		trace(DBG_USR1, "5,%d,%d\r\n", good_data, bad_data);
		return SUCCESS;
	}

	BeaconPkt bPkt;

	void sendBeacon(int32_t loc_sample_interval)
	{
		trace(DBG_USR1, "9,%d\r\n", loc_sample_interval);
		atomic {
			bPkt.hdr.type = CSMA_BEACON;
			bPkt.hdr.src_id = TOS_LOCAL_ADDRESS;
			bPkt.hdr.dest_id = CSMA_BROADCAST_ADDRESS;
			bPkt.sample_interval = loc_sample_interval;
			bPkt.sample_jiffies = SAMPLE_INTERVAL_JIFFIES;
		}

		call PhyComm.txPkt(&bPkt, sizeof(bPkt));
		/* Beacon needs to broadcast current interval and sampling jiffies */
	}

	task void setSampleTimer()
	{
		uint32_t local_ts;
		uint8_t i;

		call PTimer.clearAlarm();
		call Leds.redToggle();

		local_ts = call PTimer.getTime32();
		atomic {
			if ((sample_interval % SAMPLE_INTERVAL_TO_BEACON_RATIO) == 0)
				sendBeacon(sample_interval);
			++sample_interval;
		}
		call PSampleTimer.setAlarm(local_ts + SAMPLE_INTERVAL_JIFFIES);
	}

	async event result_t PSampleTimer.alarmFired(uint32_t val)
	{
		atomic sample_start_ts = call PTimer.getTime32();
		post setSampleTimer();
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

	event result_t PhyControl.stopDone()
	{
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		trace(DBG_USR1, "1,%d\r\n", NUM_NODES);
		call PhyControl.init();
		return SUCCESS;
	}

	event result_t PhyControl.initDone()
	{
		return call PhyControl.start();
	}

	event result_t PhyControl.startDone()
	{
		uint32_t local_ts;
#if 1
		call BackoffControl.enableBackoff();
		call BackoffControl.setMode(1);
		call BackoffControl.setRandomLimits(5, 20);
		call BackoffControl.setRetries(20);
#endif
		post setSampleTimer();

		local_ts = call PTimer.getTime32();
		call PTestTimer.setAlarm(local_ts + JIFFIES_PER_MS * (30000));
		return SUCCESS;
	}


	command result_t StdControl.stop()
	{
		call PhyControl.stop();
	}
	


}  // end of implementation

