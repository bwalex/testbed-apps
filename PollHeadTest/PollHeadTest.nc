configuration PollHeadTest { }

implementation
{
   components Main, PollHead, PollHeadTestM, LedsC, TimerC, PrecisionTimerC, RandomLFSR;
   
   Main.StdControl -> PollHeadTestM;
   PollHeadTestM.MACControl -> PollHead;
   PollHeadTestM.PollHeadComm -> PollHead;
   PollHeadTestM.PTimer -> PrecisionTimerC.PrecisionTimer[1];
   PollHeadTestM.PSampleTimer -> PrecisionTimerC.PrecisionTimer[2];
   PollHeadTestM.PTestTimer -> PrecisionTimerC.PrecisionTimer[3];
   PollHeadTestM.PTimerControl -> PrecisionTimerC.StdControl;
   PollHeadTestM.Leds -> LedsC;
   PollHeadTestM.Random -> RandomLFSR;
}




