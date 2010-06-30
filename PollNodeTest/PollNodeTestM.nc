module PollNodeTestM
{
   provides interface StdControl;
   uses {
      interface SplitControl as MACControl;
      interface PollNodeComm;
      interface Leds;
      interface Timer as TimeoutTimer;
   }
}

implementation
{
#include "PollMsg.h"
   AppPkt *pPkt;
   AppPkt pkt;
   uint8_t n;
   uint8_t acked;

   event result_t TimeoutTimer.fired()
   {
		return SUCCESS;
   }

   command result_t StdControl.init()
   {
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
		return SUCCESS;
   }

   event result_t MACControl.stopDone()
   {
	   return SUCCESS;
   }

   command result_t StdControl.start()
   {
		atomic n = 0;
		trace(DBG_USR1, "PollNodeTestM StdControl.start() called\r\n");
		call MACControl.init();
		return SUCCESS;
   }

   command result_t StdControl.stop()
   {
		call MACControl.stop();
   }

   event result_t PollNodeComm.dataRequested(void *data)
   {
		pkt.data[0] = 6;
		atomic {
			pkt.data[1] = n++;
		}
		trace(DBG_USR1, "txData called...\r\n");
		atomic {
			if (acked == 0)
				trace(DBG_USR1, "last packed was not acked!\r\n");
		}
		atomic acked = 0;
		call PollNodeComm.txData(&pkt, sizeof(pkt));
		return SUCCESS;
   }

   event result_t PollNodeComm.ackReceived(void *data)
   {
		atomic acked = 1;
		return SUCCESS;
   }
 
   event result_t PollNodeComm.dataTxFailed()
   {
		trace(DBG_USR1, "PollNodeComm.dataTxFailed() called\r\n");
		return SUCCESS;
   }

	


}  // end of implementation

