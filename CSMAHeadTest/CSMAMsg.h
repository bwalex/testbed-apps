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
 * Authors:	Alex Hornung <ahornung@gmail.com>
 * Date created: 30/06/2010
 */

#ifndef CSMA_MSG
#define CSMA_MSG

#include "PhyRadioMsg.h"

#define CSMA_BEACON 1
#define CSMA_DATA   2
#define CSMA_BROADCAST_ADDRESS  0xff

typedef struct {
	PhyHeader hdr;   // include lower-layer header first
  uint16_t src_id;
  uint16_t dest_id;
  uint16_t type;
  uint16_t pad2;
  uint32_t sample_interval;
} __attribute__((packed)) CSMAHeader;

typedef struct {
	CSMAHeader hdr;
	uint32_t sample_interval;
	uint32_t sample_jiffies;
	int16_t crc;   // crc must be the last field -- required by PhyRadio
} __attribute__((packed)) BeaconPkt;

//#define APP_PAYLOAD_LEN (100 - sizeof(AppHeader) - 2)
/*
 * set APP_PAYLOAD_LEN to whatever you want, just keep in mind that
 * the total packet size, including PHY Header, MAC Header and
 * checksum tail CANNOT exceed 128 bytes.
 */
#define APP_PAYLOAD_LEN   44

typedef struct {
	CSMAHeader hdr;
	char data[APP_PAYLOAD_LEN];
	int16_t crc;   // crc must be the last field -- required by PhyRadio
} __attribute__((packed)) CSMAPkt;

#endif //POLL_MSG
