module CSMANodeTestM
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

	BeaconPkt *bPkt;
	norace uint16_t node_id;
	uint32_t pad[16];
	uint32_t sample_interval;
	uint32_t sample_jiffies;
	uint32_t sleep_jiffies;
	uint32_t sample_start_ts;
	uint32_t temp_ts;
	uint32_t n;

	void sendData();

	task void setSampleTimer()
	{
		uint8_t i;

		//call Leds.redToggle();

		atomic {
			++sample_interval;
			sendData();
			call PSampleTimer.setAlarm(sample_start_ts + sample_jiffies);
		}
	}

	event result_t PhyComm.txPktDone(void *msg, uint8_t err)
	{
		uint32_t local_ts, loc_sleep_ts;

		if (err) {
			trace(DBG_USR1, "txPktDone failed, err=%d\r\n", err);
			call Leds.redToggle();
		} else {
			++n;
			call Leds.greenToggle();
			local_ts = call PTimer.getTime32();
			atomic loc_sleep_ts = sleep_jiffies - (local_ts - sample_start_ts);
			/* XXX: go to sleep now */
		}

		return SUCCESS;
	}

	event result_t PhyComm.startSymDetected(void* foo)
	{
		atomic temp_ts = call PTimer.getTime32();
		return SUCCESS;
	}

	event void * PhyComm.rxPktDone(void *data, uint8_t err)
	{
		uint32_t node_ready_ts;
		float rtt_ms, std_ms;
		uint16_t id;
		uint32_t loc_sample_interval;

		//call TimeoutTimer.stop();
		/* Unset the Timeout as we've received the packet already */
		atomic loc_sample_interval = sample_interval;

		if (err)
			return data;
		bPkt = (BeaconPkt *)data;
		if (bPkt->hdr.type != CSMA_BEACON)
			return data;
		atomic {
			sample_interval = bPkt->sample_interval;
			sample_jiffies = bPkt->sample_jiffies;
			node_id = bPkt->hdr.src_id;
			call PSampleTimer.clearAlarm();
			call PSampleTimer.setAlarm(temp_ts + sample_jiffies);
			++sample_interval;
			sendData();
		}
		//call Leds.yellowToggle();
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
		return SUCCESS;
	}

	CSMAPkt appPkt;

	void sendData()
	{
		result_t ret;
		atomic {
			appPkt.hdr.src_id = TOS_LOCAL_ADDRESS;
			appPkt.hdr.dest_id = node_id;
			appPkt.hdr.type = CSMA_DATA;
			appPkt.hdr.sample_interval = sample_interval;
			*((uint32_t *)appPkt.data) = n;
			ret = call PhyComm.txPkt(&appPkt, sizeof(appPkt));
		}
		if (ret == FAIL)
			trace(DBG_USR1, "PhyComm.txPkt() failed miserably!\r\n");
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
		call BackoffControl.setRandomLimits(50, 600);
		call BackoffControl.setRetries(15);
#endif
		return SUCCESS;
	}


	command result_t StdControl.stop()
	{
		call PhyControl.stop();
	}
	


}  // end of implementation

