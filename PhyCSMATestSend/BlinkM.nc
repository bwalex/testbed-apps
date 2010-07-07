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
    interface BackoffControl;
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
    call Leds.yellowToggle();
    atomic *((uint16_t *)(pktBuf.data)) = TOS_LOCAL_ADDRESS;
    atomic pktBuf.data[2] = n;
    /* Size is PhyHeader + our 4 data bytes + 2 bytes FCS*/
    if ((call PhyComm.txPkt(&pktBuf, sizeof(PhyHeader) + 4 + 2)) == FAIL) {
	}
    
  return SUCCESS;
  }

  event result_t PhyComm.txPktDone(void *msg, uint8_t error) {
	if (error) {
		call Leds.redToggle();
	} else {
		atomic ++n;
		call Leds.greenToggle();
	}
  	return SUCCESS;
  }
 
  event void * PhyComm.rxPktDone(void *msg, uint8_t error) {
	return msg;
  }

   event result_t PhyComm.startSymDetected(void* pkt)
   {
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
	call BackoffControl.enableBackoff();
	call BackoffControl.setMode(1);
	call BackoffControl.setRandomLimits(2, 10);
	call BackoffControl.setRetries(4);
	return call Timer.start(TIMER_REPEAT, 100);
  }
  event result_t PhyControl.stopDone() {
	return SUCCESS;
  }

}


