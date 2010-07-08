configuration CSMAHeadTest { }

implementation
{
   components Main, PhyRadio, CSMAHeadTestM, LedsC, TimerC, PrecisionTimerC, RandomLFSR;
   
   Main.StdControl -> CSMAHeadTestM;
   CSMAHeadTestM.PhyControl -> PhyRadio.SplitControl;
   CSMAHeadTestM.PhyState -> PhyRadio;
   CSMAHeadTestM.PhyComm -> PhyRadio;
   CSMAHeadTestM.BackoffControl -> PhyRadio;
   CSMAHeadTestM.TimeoutTimer -> TimerC.Timer[unique("Timer")];
   CSMAHeadTestM.SampleTimer -> TimerC.Timer[unique("Timer")];
   CSMAHeadTestM.PTimer -> PrecisionTimerC.PrecisionTimer[1];
   CSMAHeadTestM.PSampleTimer -> PrecisionTimerC.PrecisionTimer[2];
   CSMAHeadTestM.PTestTimer -> PrecisionTimerC.PrecisionTimer[3];
   CSMAHeadTestM.PTimerControl -> PrecisionTimerC.StdControl;
   CSMAHeadTestM.Leds -> LedsC;
   CSMAHeadTestM.Random -> RandomLFSR;
}




