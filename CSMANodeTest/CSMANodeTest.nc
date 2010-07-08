configuration CSMANodeTest { }

implementation
{
   components Main, PhyRadio, CSMANodeTestM, LedsC, TimerC, PrecisionTimerC, RandomLFSR;
   
   Main.StdControl -> CSMANodeTestM;
   CSMANodeTestM.PhyControl -> PhyRadio.SplitControl;
   CSMANodeTestM.PhyState -> PhyRadio;
   CSMANodeTestM.PhyComm -> PhyRadio;
   CSMANodeTestM.BackoffControl -> PhyRadio;
   CSMANodeTestM.TimeoutTimer -> TimerC.Timer[unique("Timer")];
   CSMANodeTestM.SampleTimer -> TimerC.Timer[unique("Timer")];
   CSMANodeTestM.PTimer -> PrecisionTimerC.PrecisionTimer[1];
   CSMANodeTestM.PSampleTimer -> PrecisionTimerC.PrecisionTimer[2];
   CSMANodeTestM.PTestTimer -> PrecisionTimerC.PrecisionTimer[3];
   CSMANodeTestM.PTimerControl -> PrecisionTimerC.StdControl;
   CSMANodeTestM.Leds -> LedsC;
   CSMANodeTestM.Random -> RandomLFSR;
}




