configuration PollHeadTest { }

implementation
{
   components Main, PollHead, PollHeadTestM, LedsC, TimerC, PrecisionTimerC;
   
   Main.StdControl -> PollHeadTestM;
   PollHeadTestM.MACControl -> PollHead;
   PollHeadTestM.PollHeadComm -> PollHead;
   PollHeadTestM.TimeoutTimer -> TimerC.Timer[unique("Timer")];
   PollHeadTestM.SampleTimer -> TimerC.Timer[unique("Timer")];
   PollHeadTestM.PTimer -> PrecisionTimerC.PrecisionTimer[1];
   PollHeadTestM.PTimerControl -> PrecisionTimerC.StdControl;
   PollHeadTestM.Leds -> LedsC;
}




