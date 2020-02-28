/*
 * FreeModbus Libary: PIC Port
 * Copyright (C) 2006 Christian Walter <wolti@sil.at>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * File: $Id: port.h,v 1.1 2006/08/22 21:35:13 wolti Exp $
 */

#ifndef _PORT_H
#define _PORT_H


#include "DSP28x_Project.h"

//#define configCPU_CLOCK_HZ				( ( unsigned long ) 37500000 ) 	//lspd_per_clock
#define configCPU_CLOCK_HZ				( ( unsigned long ) 75000000 ) 	//lspd_per_clock		// Changed to 75MHz to allow SPICLK to operate at 16MHz


#define	INLINE                      inline
#define PR_BEGIN_EXTERN_C           extern "C" {
#define	PR_END_EXTERN_C             }

//#define ENTER_CRITICAL_SECTION( )  __builtin_disi(0x3FFF)
//#define EXIT_CRITICAL_SECTION( )   __builtin_disi(0x0000)
//#define ENTER_CRITICAL_SECTION( ) ENABLE_INTERRUPTS
//#define EXIT_CRITICAL_SECTION( )  DISABLE_INTERRUPTS
#define ENTER_CRITICAL_SECTION( )  asm(" NOP")
#define EXIT_CRITICAL_SECTION( )   asm(" NOP")

#define TRANSMIT_ON_485( ) GpioDataRegs.GPBSET.bit.GPIO37 = 1			// Config for uNMR F28335
#define RECEIVE_ON_485( ) GpioDataRegs.GPBCLEAR.bit.GPIO37 = 1			// Config for uNMR F28335

#ifndef TRUE
#define TRUE            1
#endif

#ifndef FALSE
#define FALSE           0
#endif

typedef char BOOL;

typedef unsigned char UCHAR;
typedef char CHAR;

typedef unsigned short USHORT;
typedef short SHORT;

typedef unsigned long ULONG;
typedef long LONG;

#endif

