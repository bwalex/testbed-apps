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
	uint32_t n;
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

	/*
	 * On start, initialize the MAC layer.
	 */
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

	/*
	 * The MAC received a data request. Load the payload into the packet and
	 * send it.
	 */
	event result_t PollNodeComm.dataRequested(void *data)
	{
		/* Set the payload */
		atomic {
			*((uint32_t *)pkt.data) = n;
		}
		atomic {
			if (acked == 0)
				trace(DBG_USR1, "last packed was not acked!\r\n");
		}
		atomic acked = 0;
		call Leds.redToggle();
		/* Transmit data */
		call PollNodeComm.txData(&pkt, sizeof(pkt));
		return SUCCESS;
	}

	/*
	 * We've received an ACK for our data. Be happy about it!
	 */
	event result_t PollNodeComm.ackReceived(void *data)
	{
		call Leds.greenToggle();
		atomic acked = 1;
		atomic ++n;
		return SUCCESS;
	}
 
	event result_t PollNodeComm.dataTxFailed()
	{
		trace(DBG_USR1, "PollNodeComm.dataTxFailed() called\r\n");
		return SUCCESS;
	}

	


}  // end of implementation

