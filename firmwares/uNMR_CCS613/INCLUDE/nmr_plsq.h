/*
 * nmr_plsq.h
 *
 *  Created on: Aug 4, 2016
 *      Author: mccowan1
 */

#ifndef INCLUDE_NMR_PLSQ_H_
#define INCLUDE_NMR_PLSQ_H_


//  NMR DEMO FIRMWARE
//  util.h
//  Written by Dongwan Ha, 01/14/2013
//
//  This module contains definitions for common utility functions.
//
//  Functionality:
//
//  Description needs to be updated here.
//
//  Required Hardware:
//  1. Cerebot 32MX4
//  2. NMR interface board (plugged into header JB)
//
//  Revision History:
//  01/14/2013 (DongwanH): created

//  Include headers

/*

#ifndef NMR_PLSQ_H
#define	NMR_PLSQ_H

#include <plib.h>
#include "GenericTypeDefs.h"
#include "HardwareProfile.h"

*/


typedef struct {

	Uint32 dword[2];

} SglPls;


// data structure for entire pulse sequence
typedef struct {
    SglPls pls[64];
} PlsSeq;


Uint32 FID2 (PlsSeq* plsq, Uint32 *parameters);
Uint32 IR (PlsSeq* plsq, Uint32 *parameters);
Uint32 CPMG2 (PlsSeq* plsq, Uint32 *parameters);
Uint32 IRCPMG (PlsSeq* plsq, Uint32 *parameters);

Uint32 TuningSeq (PlsSeq* plsq, Uint32 *parameters);





// local

SglPls* plscpy(SglPls* dst, SglPls* src);

SglPls PlsGen(Uint32 width, Uint32 space, Uint32 amp, Uint32 phase,
		Uint32 acq, Uint32 q, Uint32 ls, Uint32 le);



void PlsGenAddLoop(SglPls *thePls, Uint32 ls, Uint32 le);
SglPls PlsGenDelay(Uint32 delay);
SglPls PlsGenPulse(Uint32 PulseWidth, Uint32 ampl, Uint32 phase, Uint32 q);
SglPls PlsGenACQ(Uint32 dwell, Uint32 TD);
Uint32 GetPlsTime (SglPls *inPls);




#endif /* INCLUDE_NMR_PLSQ_H_ */
