configuration PollNodeTest { }

implementation
{
   components Main, PollNode, PollNodeTestM, LedsC, SingleTimer;
   
   Main.StdControl -> PollNodeTestM;
   PollNodeTestM.MACControl -> PollNode;
   PollNodeTestM.PollNodeComm -> PollNode;
   PollNodeTestM.TimeoutTimer -> SingleTimer;
   PollNodeTestM.Leds -> LedsC;
}




