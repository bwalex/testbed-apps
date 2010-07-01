configuration PollHeadTest { }

implementation
{
   components Main, PollHead, PollHeadTestM, LedsC, TimerC;
   
   Main.StdControl -> PollHeadTestM;
   PollHeadTestM.MACControl -> PollHead;
   PollHeadTestM.PollHeadComm -> PollHead;
   PollHeadTestM.TimeoutTimer -> TimerC.Timer[unique("Timer")];
   PollHeadTestM.SampleTimer -> TimerC.Timer[unique("Timer")];
   PollHeadTestM.Leds -> LedsC;
}




