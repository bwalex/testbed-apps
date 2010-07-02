configuration PrecisionTimerTest { }

implementation
{
   components Main, PrecisionTimerTestM, LedsC, PrecisionTimerC, TimerC;
   
   Main.StdControl -> PrecisionTimerTestM;
   PrecisionTimerTestM.PTimer -> PrecisionTimerC.PrecisionTimer[1];
   PrecisionTimerTestM.PTimerControl -> PrecisionTimerC.StdControl;
   PrecisionTimerTestM.Timer -> TimerC.Timer[unique("Timer")];
   PrecisionTimerTestM.Leds -> LedsC;
}




