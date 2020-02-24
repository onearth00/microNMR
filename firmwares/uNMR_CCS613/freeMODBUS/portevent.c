/*
 * FreeModbus Libary: STR71x Port
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
 * File: $Id: portevent.c,v 1.1 2006/11/02 23:14:44 wolti Exp $
 */

/* ----------------------- System includes ----------------------------------*/
//#include "assert.h"

/* ----------------------- Modbus includes ----------------------------------*/
#include "mb.h"
#include "mbport.h"

/* ----------------------- Variables ----------------------------------------*/

#define PortEventQueue_Size 2

typedef struct _PortEventStruct__
{
	volatile UCHAR m_Read;
	volatile UCHAR m_Write;
	volatile eMBEventType m_Data[PortEventQueue_Size];
} PortEventStruct;

PortEventStruct portMBox;



/* ----------------------- Start implementation -----------------------------*/
BOOL
xMBPortEventInit( void )
{
	portMBox.m_Read = 0;
	portMBox.m_Write = 0;
    return TRUE;
}

BOOL
xMBPortEventPost( eMBEventType eEvent )
{
	UCHAR nextElement = (portMBox.m_Write + 1);
	if (nextElement> (PortEventQueue_Size-1)) nextElement = 0; // crude modulo arithmetic
    if(nextElement != portMBox.m_Read)
    {
    	portMBox.m_Data[portMBox.m_Write] = eEvent;
    	portMBox.m_Write = nextElement;
        return TRUE;
    }
    else return FALSE;
}

BOOL
xMBPortEventGet( eMBEventType * eEvent )
{
	if(portMBox.m_Read == portMBox.m_Write)
		return FALSE;
	UCHAR nextElement = (portMBox.m_Read + 1);
	if (nextElement> (PortEventQueue_Size-1)) nextElement = 0; // crude modulo arithmetic
	*eEvent = portMBox.m_Data[portMBox.m_Read];
	portMBox.m_Read = nextElement;
	return TRUE;
}

