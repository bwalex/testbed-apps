// $Id: BlinkM.nc,v 1.5 2003/10/07 21:44:45 idgay Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Implementation for Blink application.  Toggle the red LED when a
 * Timer fires.
 **/
module BlinkM {
  provides {
    interface StdControl;
  }
  uses {
    interface Timer;
    interface Leds;
    interface SplitControl as PhyControl;
    interface PhyState;
    interface PhyComm;
  }
}
implementation {
#include "PhyRadioMsg.h"
  PhyPktBuf pktBuf;
  uint8_t n;

  /**
   * Initialize the component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.init() {
    n = 0;
    call Leds.init();
    call PhyControl.init();
    return SUCCESS;
  }

  /**
   * Start things up.  This just sets the rate for the clock component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.start() {
    // Start a repeating timer that fires every 1000ms
    trace(DBG_USR1, "StdControl.start() in BlinkM called \r\n");
    return SUCCESS;
  }

  /**
   * Halt execution of the application.
   * This just disables the clock component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.stop() {
    call PhyControl.stop();
    return call Timer.stop();
  }


  /**
   * Toggle the red LED in response to the <code>Timer.fired</code> event.  
   *
   * @return Always returns <code>SUCCESS</code>
   **/
  
  event result_t Timer.fired()
  {
#if 0
    call Leds.redOff();
    call Leds.greenOff();
    pktBuf.data[0] = 0;
    pktBuf.data[1] = 1;
    pktBuf.data[2] = 2;
    pktBuf.data[3] = n++;
    /* Size is PhyHeader + our 4 data bytes */
    if ((call PhyComm.txPkt(&pktBuf, sizeof(PhyHeader) + 4)) == FAIL)
        call Leds.yellowToggle();
#endif
  call Leds.yellowToggle();
  return SUCCESS;
  }

  event result_t PhyComm.txPktDone(void *msg, uint8_t error) {
#if 0
	if (error)
		call Leds.redOn();
	else
		call Leds.greenOn();
#endif
	return SUCCESS;
  }
 
  event void * PhyComm.rxPktDone(void *msg, uint8_t error) {
	PhyPktBuf *pBuf;
	pBuf = msg;
	trace(DBG_USR1, "Got packet from %d, seq=%d, err=%d\r\n", *((uint16_t *)(pBuf->data)), pBuf->data[2], error);

	call Leds.greenToggle();
	return msg;
  }

   event result_t PhyComm.startSymDetected(void* pkt)
   {
      trace(DBG_USR1, "BlinkM: detected start Symbol!\r\n");
      return SUCCESS;
   }
 
  event result_t PhyControl.initDone() {
	//return call Timer.start(TIMER_REPEAT, 1000);
	trace(DBG_USR1, "PhyControl.initDone() called, calling PhyControl.start()\r\n");
	call PhyControl.start();
	return SUCCESS;
  }
  event result_t PhyControl.startDone() {
	trace(DBG_USR1, "PhyControl.startDone() called\r\n");
	return call Timer.start(TIMER_REPEAT, 1000);
	return SUCCESS;
  }
  event result_t PhyControl.stopDone() {
	return SUCCESS;
  }

}


