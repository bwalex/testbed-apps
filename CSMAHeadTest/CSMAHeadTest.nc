configuration CSMAHeadTest { }

implementation
{
   components Main, PhyRadio2, CSMAHeadTestM, LedsC, TimerC, PrecisionTimerC, RandomLFSR;
   
   Main.StdControl -> CSMAHeadTestM;
   CSMAHeadTestM.PhyControl -> PhyRadio2.SplitControl;
   CSMAHeadTestM.PhyState -> PhyRadio2;
   CSMAHeadTestM.PhyComm -> PhyRadio2;
   CSMAHeadTestM.BackoffControl -> PhyRadio2;
   CSMAHeadTestM.PTimer -> PrecisionTimerC.PrecisionTimer[1];
   CSMAHeadTestM.PSampleTimer -> PrecisionTimerC.PrecisionTimer[2];
   CSMAHeadTestM.PTestTimer -> PrecisionTimerC.PrecisionTimer[3];
   CSMAHeadTestM.PTimerControl -> PrecisionTimerC.StdControl;
   CSMAHeadTestM.Leds -> LedsC;
   CSMAHeadTestM.Random -> RandomLFSR;
}




