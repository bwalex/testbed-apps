configuration PollHeadTest { }

implementation
{
   components Main, PollHead, PollHeadTestM, LedsC, SingleTimer;
   
   Main.StdControl -> PollHeadTestM;
   PollHeadTestM.MACControl -> PollHead;
   PollHeadTestM.PollHeadComm -> PollHead;
   PollHeadTestM.TimeoutTimer -> SingleTimer;
   PollHeadTestM.SampleTimer -> SingleTimer;
   PollHeadTestM.Leds -> LedsC;
}




