module PrecisionTimerTestM
{
   provides interface StdControl;
   uses {
      interface Leds;
      interface Timer;
      interface PrecisionTimer as PTimer;
      interface StdControl as PTimerControl;
   }
}

implementation
{
#define NTESTS 		10
#define ITERATIONS	10
#define JIFFIES_PER_MS	3250
   typedef struct {
	uint16_t sleep_ms;
	uint32_t sleep_jiffies;
	uint8_t count;
   } TestCase;

   norace TestCase tests[NTESTS];
   norace uint8_t currentTest;
   norace uint32_t start_ts;
   norace uint8_t cpu_intensive;

   task void setPTimer()
   {
		atomic start_ts = call PTimer.getTime32();
		call PTimer.setAlarm(start_ts + tests[currentTest].sleep_jiffies);
   }

   task void CPUIntensive()
   {
		int i = 0;
		int32_t a;
		int32_t b;
		double e,f;

		a = call PTimer.getTime32();
		b = call PTimer.getTime32();
		for (i = 0; i < 100; i++) {
			e = a * 1.512 - b * 0.2591;
			f = f *e/1921.593;
			if (f < 1)
				f += e*312;
			if (f < 1)
				f += 1394;
		}
		post CPUIntensive();
		
   }

   event result_t Timer.fired()
   {
		uint32_t end_ts;
		float ms;

		end_ts = call PTimer.getTime32();
		ms = (end_ts - start_ts - 0.0)/3250.0;
		trace(DBG_USR1, "1,%d,%d,%d,%f,%d\r\n", cpu_intensive, currentTest, tests[currentTest].count, ms, tests[currentTest].sleep_ms);

		if (++tests[currentTest].count == ITERATIONS) {
			tests[currentTest].count = 0;
			if (++currentTest == NTESTS) {
				currentTest = 0;
				post setPTimer();
				//atomic start_ts = call PTimer.getTime32();
				//call PTimer.setAlarm(start_ts + tests[currentTest].sleep_jiffies);
			} else {
				atomic start_ts = call PTimer.getTime32();
				call Timer.start(TIMER_ONE_SHOT, tests[currentTest].sleep_ms);
			}
		} else {
			atomic start_ts = call PTimer.getTime32();
			call Timer.start(TIMER_ONE_SHOT, tests[currentTest].sleep_ms);
		}
		return SUCCESS;
   }

   async event result_t PTimer.alarmFired(uint32_t val)
   {
		uint32_t end_ts;
		float ms;

		end_ts = call PTimer.getTime32();
		ms = (end_ts - start_ts - 0.0)/3250.0;
		trace(DBG_USR1, "2,%d,%d,%d,%f,%d\r\n", cpu_intensive, currentTest, tests[currentTest].count, ms, tests[currentTest].sleep_ms);

		if (++tests[currentTest].count == ITERATIONS) {
			tests[currentTest].count = 0;
			if (++currentTest == NTESTS) {
				currentTest = 0;
				cpu_intensive = 1;
				atomic start_ts = call PTimer.getTime32();
				call Timer.start(TIMER_ONE_SHOT, tests[currentTest].sleep_ms);
				post CPUIntensive();
			} else {
				post setPTimer();
				//atomic start_ts = call PTimer.getTime32();
				//call PTimer.setAlarm(start_ts + tests[currentTest].sleep_jiffies);
			}
		} else {
			post setPTimer();
			//atomic start_ts = call PTimer.getTime32();
			//call PTimer.setAlarm(start_ts + tests[currentTest].sleep_jiffies);
		}
		return SUCCESS;	
   }

   command result_t StdControl.init()
   {
      call Leds.init();
      call PTimerControl.init();
      return SUCCESS;
   }

   command result_t StdControl.start()
   {
	int i;

	tests[0].sleep_ms = 5;
	tests[1].sleep_ms = 10;
	tests[2].sleep_ms = 35;
	tests[3].sleep_ms = 50;
	tests[4].sleep_ms = 100;
	tests[5].sleep_ms = 230;
	tests[6].sleep_ms = 400;
	tests[7].sleep_ms = 650;
	tests[8].sleep_ms = 900;
	tests[9].sleep_ms = 1250;

	for (i = 0; i < NTESTS; i++) {
		tests[i].sleep_jiffies = ((uint32_t)tests[i].sleep_ms)*JIFFIES_PER_MS;
		tests[i].count = 0;
	}

	currentTest = 0;
	atomic start_ts = call PTimer.getTime32();
	call Timer.start(TIMER_ONE_SHOT, tests[0].sleep_ms);
	//post CPUIntensive();
	return SUCCESS;
   }

   command result_t StdControl.stop()
   {
   }


}  // end of implementation

