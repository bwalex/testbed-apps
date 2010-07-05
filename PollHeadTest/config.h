/*									tab:4
 * Copyright (c) 2002 the University of Southern California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF SOUTHERN CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
 * UNIVERSITY OF SOUTHERN CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * THE UNIVERSITY OF SOUTHERN CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF SOUTHERN CALIFORNIA HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 * Authors:	Wei Ye
 *
 * This file configures the Physical layer, S-MAC and the application.
 * This file is supposed to be included before any other files in an 
 * application's configuration file, such as SMACTest.nc, so that these
 * macro definations will override default definations in other files.
 * These macros are in the global name space, so use a prefix to indicate
 * which layers they belong to.
 *
 */

#ifndef CONFIG
#define CONFIG

// Configure Physical layer. Definitions here override default values
// Default values are defined in PhyMsg.h
// --------------------------------------------------------------
//#define PHY_MAX_PKT_LEN 50       // max: 250 (bytes), default: 100

// carrier sense threshold to determine a busy channel
// smaller value -> higher threshold -> more aggressive Tx
// this is only for mica2 and mica2dot
//#define RADIO_BUSY_THRESHOLD 0xb5  // 0x60 - 0xff, default: 0xb5

// Configure S-MAC into different operating modes 
// -----------------------------------------------
//#define SMAC_DUTY_CYCLE 50       // 1 - 99 (%), default: 10
//#define SMAC_NO_ADAPTIVE_LISTEN  // default: adaptive listen is enabled
#define SMAC_NO_SLEEP_CYCLE      // default: low duty cycle mode

// With the following macro defined, the node is configured as a slave on
// sleep schedules. It keeps listening to SYNC packets until it receives
// one and adopts it. With one master node and all other nodes as slaves,
// its easy to set up a network with only the master's schedule.
//#define SMAC_SLAVE_SCHED

// User adjustable S-MAC parameters
// ---------------------------------
// Definitions here override default values in SMACConst.h

//#define SMAC_MAX_NUM_NEIGHB 20  // default value 20
//#define SMAC_MAX_NUM_SCHED 4    // default value 4
//#define SMAC_RTS_RETRY_LIMIT 7  // default value 7
//#define SMAC_DATA_RETX_LIMIT 3  // default value 3

// the following macro defines the maximum time that S-MAC can hold a message
// for transmission. If it cannot send out the message within the time, it
// will drop the message and signal upper layer tx failure.
// default value: 2min in low duty cycle mode and 10s in fully active mode
//#define SMAC_MAX_TX_MSG_TIME 120000

// The following two macros define the period to search for potential 
// neighbors on different schedules. The period is expressed as the
// number of SYNC_PERIODs (10s). Therefore, 30 means after every 30
// SYNC_PERIODs, which is 300s, the node will keep listening for an entire
// SYNC_PERIOD. Maximum value is 255.
// The SHORT_PERIOD is used when I have no neighbor -- search more aggressively
// The LONG_PERIOD is used when I have neighbors -- don't perform too often
//#define SMAC_SRCH_NBR_SHORT_PERIOD 3  // max: 255, default: 3  (30s)
//#define SMAC_SRCH_NBR_LONG_PERIOD 30  // max: 255, default: 30 (300s)


// Now by default, S-MAC uses timer/counter 0, which conflicts with Clock
// and Timer components. If you want to use Timer or Clock, uncomment the
// following line to let S-MAC use the 16-bit timer/counter 1
#define SMAC_USE_COUNTER_1

// define the following macro to put a time stamp on each outgoing packet
//#define SMAC_TX_TIME_STAMP
// TST_MSG_INTERVAL controls how fast a node generates a message. Setting
// it to 0 makes it generates second packet right after the first is sent.

// Configure the test application
// -------------------------------
#define TST_MIN_NODE_ID 1        // at least 2 nodes. node IDs must be
#define TST_MAX_NODE_ID 2        // consecutive from min to max
#define TST_MSG_INTERVAL 500     // in ms

// By default, each node keeps sending until it is powered off.
// To let a node automatically stop after sending sepecified number of 
// messages, define the following macro
//#define TST_NUM_MSGS 20

// number of fragments in each unicast test message, max: 8
#define TST_NUM_FRAGS 1

// By default, each node alternate in sending broadcast and unicast
// for unicast, node i sends to (i+1), and node MaxId sends to MinId
//#define TST_BROADCAST_ONLY      // test broadcast only if defined
//#define TST_UNICAST_ONLY        // test unicast only if defined
//#define TST_UNICAST_ADDR 2      // specify unicast addr instead of default one
//#define TST_RECEIVE_ONLY        // set a node that only receives packets

// S-MAC debugging with a snooper
// -----------------------------
// Debug by adding bytes to data pkts, so that snooper can show them
//#define SMAC_SNOOPER_DEBUG

// S-MAC debugging with a serial port (UART)
// -----------------------------------------
// Don't enable it unless you know what's going to happen.
// There is a known problem on Mica2 motes. If UART debugging is enabled
// but the mote is not connected with the serial board/cable, very often
// it fails to start. It occasionally happens when the mote connects with
// the serial board/cable.

// The following macros are mutally exclusive. You can only define one
// Debugging with predefined S-MAC states and events
//#define SMAC_UART_DEBUG_STATE_EVENT
// Debugging by sending a byte to UART
//#define SMAC_UART_DEBUG_BYTE

#endif  // CONFIG
