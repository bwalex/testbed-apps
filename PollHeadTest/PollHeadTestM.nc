module PollHeadTestM
{
   provides interface StdControl;
   uses {
      interface SplitControl as MACControl;
      interface PollHeadComm;
      interface Leds;
	  interface Timer as TimeoutTimer;
	  interface Timer as SampleTimer;
   }
}

implementation
{
#include "PollMsg.h"
#define NUM_NODES 1
#define TIMEOUT_MS 5

	enum {
		STATUS_OK,
		STATUS_FAIL
	};
   typedef struct {
      uint8_t nodeId;
	  uint8_t status;
	  uint8_t fail_count;
   } Node;

   Node nodes[NUM_NODES];
   AppPkt pkt;
   AppPkt *pPkt;
	uint8_t node_id;

   task void pollnodes()
   {
		call TimeoutTimer.start(TIMER_ONE_SHOT, TIMEOUT_MS);
		atomic nodes[node_id].status = STATUS_OK;
		if (call PollHeadComm.requestData(node_id, &pkt, sizeof(pkt)) == FAIL)
			trace(DBG_USR1, "PollHeadComm.rquestData() failed\r\n");
   }

   event result_t PollHeadComm.requestDataDone(uint8_t id, void *data, uint8_t err)
   {
		if (nodes[id].status == STATUS_FAIL)
		{
			trace(DBG_USR1, "Node %d took too long to respond\r\n", id);
			return SUCCESS;
		}

		if (id != node_id) {
			trace(DBG_USR1, "It's likely that the sample period expired, node %d sent OOB message (node_id=%d)\r\n", id, node_id);
			return SUCCESS;
		}

		if (err) {
			trace(DBG_USR1, "error while requesting data... id=%d, node_id=%d\r\n", id, node_id);
			nodes[node_id].fail_count++;
		} else {
			trace(DBG_USR1, "data received successfully!\r\n");
			pPkt = data;
			trace(DBG_USR1, "received data = %d,%d\r\n", pPkt.data[0], pPkt.data[1]);
		}
		call TimeoutTimer.stop();
		atomic {
			if (node_id == NUM_NODES-1) {
				node_id = 0;
			} else { 
				node_id++;
				post pollnodes();
			}
		}
		return SUCCESS;
   }

   event result_t TimeoutTimer.fired()
   {
		atomic {
			nodes[node_id].status = STATUS_FAIL;
			nodes[node_id].fail_count++;
			if (node_id == NUM_NODES-1) {
				node_id = 0;
			} else {
				node_id++;
				post pollnodes();
			}
		}
		return SUCCESS;
   }

   event result_t SampleTimer.fired()
   {
		call TimeoutTimer.stop();
		atomic {
			node_id = 0;
		}
		post pollnodes();
		return SUCCESS;
   }

   command result_t StdControl.init()
   {
      node_id = 0; 
      call Leds.init();
      return SUCCESS;
   }

   event result_t MACControl.initDone()
   {
		call MACControl.start();
		return SUCCESS;
   }

   event result_t MACControl.startDone()
   {
		uint8_t i;
		atomic {
     	 	for (i = 0; i < NUM_NODES; i++) {
     		   	nodes[i].status = STATUS_OK;
				nodes[i].fail_count = 0;
       		}
		}
		/* XXX: do actual work starting here */
		atomic node_id = 0;
		call SampleTimer.start(TIMER_REPEAT, 30); /* every 30ms */
		return SUCCESS;
   }

   event result_t MACControl.stopDone()
   {
	   return SUCCESS;
   }

   command result_t StdControl.start()
   {
		trace(DBG_USR1, "SMACTest StdControl.start() called\r\n");
		call MACControl.init();
		return SUCCESS;
   }


   command result_t StdControl.stop()
   {
		call MACControl.stop();
   }


	


}  // end of implementation

