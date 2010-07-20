configuration CSMANodeTest { }

implementation
{
   components Main, PhyRadio2, CSMANodeTestM, LedsC, TimerC, PrecisionTimerC, RandomLFSR;
   
   Main.StdControl -> CSMANodeTestM;
   CSMANodeTestM.PhyControl -> PhyRadio2.SplitControl;
   CSMANodeTestM.PhyState -> PhyRadio2;
   CSMANodeTestM.PhyComm -> PhyRadio2;
   CSMANodeTestM.BackoffControl -> PhyRadio2;
   CSMANodeTestM.TimeoutTimer -> TimerC.Timer[unique("Timer")];
   CSMANodeTestM.SampleTimer -> TimerC.Timer[unique("Timer")];
   CSMANodeTestM.PTimer -> PrecisionTimerC.PrecisionTimer[1];
   CSMANodeTestM.PSampleTimer -> PrecisionTimerC.PrecisionTimer[2];
   CSMANodeTestM.PTestTimer -> PrecisionTimerC.PrecisionTimer[3];
   CSMANodeTestM.PTimerControl -> PrecisionTimerC.StdControl;
   CSMANodeTestM.Leds -> LedsC;
   CSMANodeTestM.Random -> RandomLFSR;
}




