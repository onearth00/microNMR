/*
 * nmr_plsq.c
 *
 *  Created on: Aug 4, 2016
 *      Author: mccowan1
 */



//  Early versions started with Dongwan Ha.
//
//  NMR DEMO FIRMWARE
//  nmr_plsq.c
//  Written by Dongwan Ha, 02/06/2013
//
//  This module contains common utility functions.
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
//  02/06/2013 (DongwanH): created

// 2013-14, update to make specific pulse, delay, etc. YS

//  Include headers

#include <stdlib.h>

#include "DSP28x_Project.h"												// Device Headerfile and Examples Include File
#include <RunNMR.h>
#include "nmr.h"
#include "nmr_plsq.h"

// time base for NMR:
// number of ticks for a microsecond (US) for the NMR control clock
// NMR control clock 8 MHz - for cerebot code.
// Current clock for TI (pwm) is about 15 MHz. Jan 2017 YS
const Uint32 US_NMR 	= 15;
//const Uint32 US_NMR 	= 4;
// with 15 clock, max time for 24 bit is about 1 second
const Uint32 MAXT_NMR	= 1000000;				// max time for a delay step, 1 second. Could be better defined as 24 bit.
//const Uint32 MAXT_NMR	= 2000000;				// max time for a delay step, 1 second. Could be better defined as 24 bit.
//const Uint32 MAXT_NMR	= 4194304;				// max time for a delay step, 1 second. Could be better defined as 24 bit.




// copy SglPls's entity from source to destination.
SglPls* plscpy(SglPls* dst, SglPls* src)
{
    dst->dword[0] = src->dword[0];
    dst->dword[1] = src->dword[1];
    return dst;
}


// Time related variable should be passed in microseconds.
// Now, it is all about integers. It needs to be rewritten with floating point variables.
// time parameters in Us.
SglPls PlsGen(Uint32 width, 					// RF pulse width, 24 bits, in US
        Uint32 space,       					// period after the RF pulse, 24 bits, in US
        Uint32 amp,         					// amplitude of the RF pulse, 0-31
        Uint32 phase,       					// phase of the RF pulse, 0-31
        Uint32 acq,         					// turn on acq flag during the space period
        Uint32 q,           					// turn on the reverse phase segment after the RF pulse, how long ?
        Uint32 ls, Uint32 le) 					// loop start (ls) and loop end (le), to indicate the loop structure
{
    SglPls pls;
    pls.dword[0] = pls.dword[1] = 0;

    // bit structure
    // dword[1]                         dword[0]
    // | width(24) | amp(5) | phase(5) | space(24) | q(3) | acq(1) | ls(1) | le(1) |
    //  31        8 7      3 2  0 31 30 29        6 5    3 2      2 1     1 0     0
    pls.dword[0]   |= (((space*US_NMR)&0xffffff) << 6) | (le&0x1) | ((ls&0x1) << 1) | ((acq&0x1) << 2) | ((q&0x7) << 3) | ((phase&0x03) << 30);

    pls.dword[1] 	= (((width*US_NMR)&0xffffff) << 8) | ((amp&0x1f) << 3) | ((phase&0x1c) >> 2);

    //DBPRINTF("plsgen [%08x %08x]\n", pls.word[1], pls.word[0]);

    return pls;
}

void PlsGenAddLoop(SglPls *thePls, Uint32 ls, Uint32 le) // loop start (ls) and loop end (le), to indicate the loop structure
{
    thePls->dword[0] |=(le&0x1) | ((ls&0x1) << 1);
}

SglPls PlsGenDelay(Uint32 delay)
{
    return PlsGen(0,delay,0,0,0,0,0,0);
}

SglPls PlsGenPulse(Uint32 PulseWidth, Uint32 ampl, Uint32 phase, Uint32 q)
{
    Uint32 acqDelay = 0; //US

    return PlsGen(PulseWidth,acqDelay,ampl,phase,0,q,0,0);
}

SglPls PlsGenACQ(Uint32 dwell, Uint32 TD)
{
    Uint32 PulseWidth = 0;
    Uint32 PulseAmpl = 0;
    Uint32 PulsePhase = 0;
    Uint32 q = 0;
    Uint32 AcqFlag = 1;
    Uint32 Period = dwell*TD;

    return PlsGen(PulseWidth,Period,PulseAmpl,PulsePhase,AcqFlag,q,0,0);
}

Uint32 GetPlsTime (SglPls *inPls)
{
    Uint32 tt = ((inPls->dword[0] << 2) >>8) ; // space

    tt +=  (inPls->dword[1] >>8) ;              // width
    //tt +=  ((inPls->dword[1]>>3) & 0x7);        // quench -- a mistake. YS 0217.2.27
    tt +=  ((inPls->dword[0]>>3) & 0x00000007);        // quench
    return tt;
    // return time is in the unit of ticks of the NMR clock.
    // Cerebot: The NMR board clock is 8MHz.
    // TI: 15 MHz via pwm.
}



// third version of FID
// Only to use when EN_SNS is enabled
Uint32 FID3 (PlsSeq* plsq, Uint32 *parameters)
{
    Uint32 *p = parameters;

    Uint32 i,j;
    Uint32 ad = 20; // acq delay, 20 us before acqusition, for ringdown

    Uint32 recDelay = p[0];

    // Recycle Delay
    // the max time period for one step is 24 bit, ~1 s at 8Mhz
    // MAXT_NMR in unit of us.
    Uint32 TMOD = recDelay % MAXT_NMR;
    Uint32 nprd  = recDelay / MAXT_NMR;
    SglPls tmp;

    if (plsq == NULL) return 0;

    i = 0;

    if (nprd != 0)
    {
    for (j=0;j<nprd; j++) {
        tmp = PlsGenDelay(MAXT_NMR);
        plscpy(&plsq->pls[i++], &tmp );
        }
    }
    tmp = PlsGenDelay(TMOD);
    plscpy(&plsq->pls[i++], &tmp );



    // P90
    tmp = PlsGenPulse(p[1], p[2], p[3],0);
    plscpy(&plsq->pls[i++], &tmp );

    // acq delay to allow ring to reduce
    tmp = PlsGenDelay(ad);          // ad for ringdown
    plscpy(&plsq->pls[i++], &tmp );


    // acquisition
    TMOD = (p[4]*p[5]) % MAXT_NMR;
    nprd  = (p[4]*p[5]) / MAXT_NMR;
    if (nprd != 0)
    {
    for (j=0;j<nprd; j++) {
  //     tmp = PlsGenACQ(p[4],MAXT_NMR/p[4]);
       tmp = PlsGenDelay(MAXT_NMR);
        plscpy(&plsq->pls[i++], &tmp );
        }
    }

    //tmp = PlsGenACQ(p[4],TMOD/p[4]);
    tmp=PlsGenDelay(TMOD);
    plscpy(&plsq->pls[i++], &tmp );


    // fill the empty space.
    for (;i < 64; i++) {
        plsq->pls[i].dword[0] = plsq->pls[i].dword[1] = 0;
    }

    recDelay = 0;
    for (i=0;i<64;i++)
    {
        recDelay += GetPlsTime(&(plsq->pls[i]));
        // DBPRINTF("plsgen [%08x %08x]\n", plsq->pls[i].dword[1], plsq->pls[i].dword[0]);
        // expTime is in the unit of ticks on the NMR board. Each tick is 1/8 us.
        // The NMR board clock is 8MHz.
    }

    return recDelay/US_NMR; // in microsecond
}// end of FID3



Uint32 FID2 (PlsSeq* plsq, Uint32 *parameters)
{
    Uint32 *p = parameters;

    Uint32 i,j;
    Uint32 ad = 20; // acq delay, 20 us before acqusition, for ringdown

    Uint32 recDelay = p[0];

    // Recycle Delay
    // the max time period for one step is 24 bit, ~1 s at 8Mhz
    // MAXT_NMR in unit of us.
    Uint32 TMOD = recDelay % MAXT_NMR;
    Uint32 nprd  = recDelay / MAXT_NMR;
    SglPls tmp;

    if (plsq == NULL) return 0;

    i = 0;

    if (nprd != 0)
    {
    for (j=0;j<nprd; j++) {
        tmp = PlsGenDelay(MAXT_NMR);
        plscpy(&plsq->pls[i++], &tmp );
        }
    }
    if (TMOD!=0)
    	{
    		tmp = PlsGenDelay(TMOD);
    		plscpy(&plsq->pls[i++], &tmp );
    	}


    // P90
    tmp = PlsGenPulse(p[1], p[2], p[3],0);
    plscpy(&plsq->pls[i++], &tmp );

    // acq delay to allow ring to reduce
    tmp = PlsGenDelay(ad);          // ad for ringdown
    plscpy(&plsq->pls[i++], &tmp );

    // acquisition
    TMOD = (p[4]*p[5]) % MAXT_NMR;
    nprd  = (p[4]*p[5]) / MAXT_NMR;
    if (nprd != 0)
    {
    for (j=0;j<nprd; j++) {
       tmp = PlsGenACQ(p[4],MAXT_NMR/p[4]);
  //     tmp = PlsGenDelay(MAXT_NMR);
        plscpy(&plsq->pls[i++], &tmp );
        }
    }

    tmp = PlsGenACQ(p[4],TMOD/p[4]);
    // tmp=PlsGenDelay(TMOD);
    plscpy(&plsq->pls[i++], &tmp );

	tmp = PlsGenDelay(100);
	plscpy(&plsq->pls[i++], &tmp );

    // fill the empty space.
    for (;i < 64; i++) {
        plsq->pls[i].dword[0] = plsq->pls[i].dword[1] = 0;
    }

    recDelay = 0;
    for (i=0;i<64;i++)
    {
        recDelay += GetPlsTime(&(plsq->pls[i]));
        // DBPRINTF("plsgen [%08x %08x]\n", plsq->pls[i].dword[1], plsq->pls[i].dword[0]);
        // expTime is in the unit of ticks on the NMR board. Each tick is 1/8 us.
        // The NMR board clock is 8MHz.
    }

    return recDelay/US_NMR; // in microsecond
}// end of FID2


/* YS Feb
 * Tuning sequence. A simple pulse seq
 * 100 us - pulse - RD (e.g. 1000 us).
 * Acquisition program to acquire during the pulse
 * Duplexers need to be in the tuning mode
 */

Uint32 TuningSeq (PlsSeq* plsq, Uint32 *parameters)
{
    Uint32 *p = parameters;

    Uint32 i,j;
    Uint32 ad = 20; // acq delay, 20 us before acquisition, for ringdown

    Uint32 recDelay = p[0];

    // Recycle Delay
    // the max time period for one step is 24 bit, ~1 s at 8Mhz
    // MAXT_NMR in unit of us.
    Uint32 TMOD = recDelay % MAXT_NMR;
    Uint32 nprd  = recDelay / MAXT_NMR;
    SglPls tmp;

    if (plsq == NULL) return 0;

    i = 0;

    // add a delay
      tmp = PlsGenDelay(200);          //
      plscpy(&plsq->pls[i++], &tmp );


     // P90 - just a pulse, relatively long
     // acquisition during the pulse will be handled in the acquisition program.
     tmp = PlsGenPulse(p[1], p[2], p[3],0);
     plscpy(&plsq->pls[i++], &tmp );

     // acq delay to allow ring to reduce
     tmp = PlsGenDelay(ad);          // ad for ringdown
     plscpy(&plsq->pls[i++], &tmp );



    if (nprd != 0)
    {
    for (j=0;j<nprd; j++) {
        tmp = PlsGenDelay(MAXT_NMR);
        plscpy(&plsq->pls[i++], &tmp );
        }
    }
    tmp = PlsGenDelay(TMOD);
    plscpy(&plsq->pls[i++], &tmp );





    // fill the empty space.
    for (;i < 64; i++) {
        plsq->pls[i].dword[0] = plsq->pls[i].dword[1] = 0;
    }

    recDelay = 0;
    for (i=0;i<64;i++)
    {
        recDelay += GetPlsTime(&(plsq->pls[i]));
        // DBPRINTF("plsgen [%08x %08x]\n", plsq->pls[i].dword[1], plsq->pls[i].dword[0]);
        // expTime is in the unit of ticks on the NMR board. Each tick is 1/8 us.
        // The NMR board clock is 8MHz.
    }

    return recDelay/US_NMR; // in microsecond
}// end of Tuning

//
// Second version of CPMG
//
// parameter form :
// [0]  : RD,
// [1-3]: T90, amp, ph1,
// [4-5]: T180, ph2, P180 time and phase
// [6-8]: TE, Necho, NPTS : echo time, and number of echoes, and number of pt per echo
// [9] : dw
// return the total period of time for the experiment
//

Uint32 CPMG2 (PlsSeq* plsq, Uint32 *p)
{

    Uint32 i,j;
    //Uint32 ad = 10; // acq delay, 10 us before acqusition, for ringdown
    Uint32 dw = p[9]; // dwell time, 10us.
    Uint32 recDelay = p[0];
    Uint32 TE = p[6];			// echo time
    Uint32 Necho = p[7];			// number of echoes
    Uint32 NPTS = p[8];			// number of points to acquire per echo

    // Recycle Delay
    // the max time period for one step is 24 bit, ~1 s at 8Mhz
    // MAXT_NMR in unit of us.
    Uint32 TMOD = recDelay % MAXT_NMR;
    Uint32 nprd  = recDelay / MAXT_NMR;
    SglPls tmp;

    i = 0;

    // if the seq can not be made, return 0;
    if ((nprd>64) || (TE<dw*NPTS)) return (0);

    // RD  - recycle delay
    if (nprd != 0)
    {
    for (j=0;j<nprd; j++) {
        tmp = PlsGenDelay(MAXT_NMR);
        plscpy(&plsq->pls[i++], &tmp );
        }
    }
    if (TMOD!=0)
    	{
    		tmp = PlsGenDelay(TMOD);
    		plscpy(&plsq->pls[i++], &tmp );
	}



    // P90
    tmp = PlsGenPulse(p[1], p[2], p[3],0);
    plscpy(&plsq->pls[i++], &tmp );

    //TE/2
    tmp = PlsGenDelay(TE/2);
    plscpy(&plsq->pls[i++], &tmp );

    // P180
    tmp = PlsGenPulse(p[4], p[2], p[5],0);
    PlsGenAddLoop(&tmp, 1, 0);      // the beginning of the loop, loop start bit is set
    plscpy(&plsq->pls[i++], &tmp );

    // wait TE/2-dw*NPTS
    tmp = PlsGenDelay(TE/2-dw*NPTS/2);
    plscpy(&plsq->pls[i++], &tmp );

    // acquisition
    tmp = PlsGenACQ(dw,NPTS);
    plscpy(&plsq->pls[i++], &tmp );

 // wait TE/2-dw*NPTS/2
    tmp = PlsGenDelay(TE/2-dw*NPTS/2);
    PlsGenAddLoop(&tmp, 0, 1);      // the end of the loop, loop end bit is set
    plscpy(&plsq->pls[i++], &tmp );

    // end of the seq
    // fill the rest with empty space.
    for (;i < 64; i++) {
        plsq->pls[i].dword[0] = plsq->pls[i].dword[1] = 0;
    }

    return ( p[0] + p[1] + TE/2 + (TE + p[4])*Necho);
    // in  microsecond
}// end of CPMG2

//inversion-recovery seq for T1 measurement
// IRCPMG
// FID pulse sequence generation
// parameter form :
// [0]  : RD,
// [1-3]: T90, amp, ph1,
// [4-5]: T180, ph2, P180 time and phase
// [6]: dw
// [7]: TD
// [8]: tau, recovery time
// return the total period of time for the experiment

Uint32 IR (PlsSeq* plsq, Uint32 *parameters)
{
    Uint32 *p = parameters;

    Uint32 i,j;
    Uint32 ad = 20; // acq delay, 20 us before acqusition, for ringdown

 //   Uint32 dw = p[6]; // dwell time, 10us.
    Uint32 recDelay = p[0];
 //   Uint32 tau = p[8];

    // Recycle Delay
    // the max time period for one step is 24 bit, ~1 s at 15 Mhz
    // MAXT_NMR in unit of us.
    Uint32 TMOD = recDelay % MAXT_NMR;
    Uint32 nprd  = recDelay / MAXT_NMR;
    SglPls tmp;

    i = 0;

    // RD
    if (nprd != 0)
    {
       for (j=0;j<nprd; j++) {
           tmp = PlsGenDelay(MAXT_NMR);
           plscpy(&plsq->pls[i++], &tmp );
       }
    }

    if (TMOD!=0)
    {
        tmp = PlsGenDelay(TMOD);
        plscpy(&plsq->pls[i++], &tmp );
    }

    // P180
    tmp = PlsGenPulse(p[4], p[2], p[5],0);
    plscpy(&plsq->pls[i++], &tmp );

    // recovery

    TMOD = p[8] % MAXT_NMR;
    nprd = p[8] / MAXT_NMR;

       if (nprd != 0)
       {
          for (j=0;j<nprd; j++) {
              tmp = PlsGenDelay(MAXT_NMR);
              plscpy(&plsq->pls[i++], &tmp );
          }
       }

       if (TMOD!=0)
       {
           tmp = PlsGenDelay(TMOD);
           plscpy(&plsq->pls[i++], &tmp );
       }

    // P90
    tmp = PlsGenPulse(p[1], p[2], p[3],0);
    plscpy(&plsq->pls[i++], &tmp );

    tmp = PlsGenDelay(ad);          // ad for ringdown
    plscpy(&plsq->pls[i++], &tmp );

    // acquisition
    TMOD = (p[6]*p[7]) % MAXT_NMR;
    nprd  = (p[6]*p[7]) / MAXT_NMR;
    if (nprd != 0)
    {
        for (j=0;j<nprd; j++) {
           tmp = PlsGenACQ(p[6],MAXT_NMR/p[6]);
      //     tmp = PlsGenDelay(MAXT_NMR);
            plscpy(&plsq->pls[i++], &tmp );
            }
        }

        tmp = PlsGenACQ(p[6],TMOD/p[6]);
        // tmp=PlsGenDelay(TMOD);
        plscpy(&plsq->pls[i++], &tmp );

        tmp = PlsGenDelay(100);
        plscpy(&plsq->pls[i++], &tmp );

        for (;i < 64; i++) {
                plsq->pls[i].dword[0] = plsq->pls[i].dword[1] = 0;
            }

         recDelay = 0;

         for (i=0;i<64;i++)
            {
                recDelay += GetPlsTime(&(plsq->pls[i]));
                // DBPRINTF("plsgen [%08x %08x]\n", plsq->pls[i].dword[1], plsq->pls[i].dword[0]);
                // expTime is in the unit of ticks on the NMR board. Each tick is 1/8 us.
                // The NMR board clock is 15MHz.
            }

            return recDelay/US_NMR; // in microsecond

 }

// IRCPMG
// FID pulse sequence generation
// parameter form :
// [0]  : RD,
// [1-3]: T90, amp, ph1,
// [4-5]: T180, ph2, P180 time and phase
// [6-8]: TE, Necho, NPTS : echo time, and number of echoes, and number of pt per echo
// [9]: dw
// [10]: tau1, recovery time
// [11]:phase of 1st 180 pulse
// return the total period of time for the experiment
// expTime = p[0] + p[4] + p[10]+ p[1] + TE/2 + (TE + p[4])*Necho;

Uint32 IRCPMG (PlsSeq* plsq, Uint32 *parameters)
{
    Uint32 *p = parameters;

    Uint32 i,j;
    //Uint32 ad = 10; // acq delay, 10 us before acqusition, for ringdown
    Uint32 dw = p[9]; // dwell time, 10us.
    Uint32 recDelay = p[0];
    Uint32 TE = p[6];
    Uint32 Necho = p[7];
    Uint32 NPTS = p[8];

    // Recycle Delay
    // the max time period for one step is 24 bit, ~1 s at 8Mhz
    // MAXT_NMR in unit of us.
    Uint32 TMOD = recDelay % MAXT_NMR;
    Uint32 nprd  = recDelay / MAXT_NMR;
    SglPls tmp;

    i = 0;

    // if the seq can not be made, return 0;
    if ((nprd>64) || (TE<dw*NPTS)) return (0);

    // RD
    if (nprd != 0)
    {
    for (j=0;j<nprd; j++) {
        tmp = PlsGenDelay(MAXT_NMR);
        plscpy(&plsq->pls[i++], &tmp );
        }
    }
    if (TMOD!=0)
    	{
    		tmp = PlsGenDelay(TMOD);
    		plscpy(&plsq->pls[i++], &tmp );
	}


    // P180
    tmp = PlsGenPulse(p[4], p[2], p[11],0);
    plscpy(&plsq->pls[i++], &tmp );

    // recovery
    TMOD = p[10] % MAXT_NMR;
    nprd = p[10] / MAXT_NMR;

    if (nprd != 0){
        for (j=0;j<nprd; j++) {
                 tmp = PlsGenDelay(MAXT_NMR);
                 plscpy(&plsq->pls[i++], &tmp );
             }
          }

          if (TMOD!=0)
          {
              tmp = PlsGenDelay(TMOD);
              plscpy(&plsq->pls[i++], &tmp );
          }

    // P90
    tmp = PlsGenPulse(p[1], p[2], p[3],0);
    plscpy(&plsq->pls[i++], &tmp );

    //TE/2
    tmp = PlsGenDelay(TE/2);
    plscpy(&plsq->pls[i++], &tmp );

    // P180
    tmp = PlsGenPulse(p[4], p[2], p[5],0);
    PlsGenAddLoop(&tmp, 1, 0);      // the beginning of the loop, loop start bit is set
    plscpy(&plsq->pls[i++], &tmp );

    // wait TE/2-dw*NPTS
    tmp = PlsGenDelay(TE/2-dw*NPTS/2);
    plscpy(&plsq->pls[i++], &tmp );

    // acquisition
    tmp = PlsGenACQ(dw,NPTS);
    plscpy(&plsq->pls[i++], &tmp );

 // wait TE/2-dw*NPTS/2
    tmp = PlsGenDelay(TE/2-dw*NPTS/2);
    PlsGenAddLoop(&tmp, 0, 1);      // the end of the loop, loop end bit is set
    plscpy(&plsq->pls[i++], &tmp );

    // end of the seq
    // fill the rest with empty space.
    for (;i < 64; i++) {
        plsq->pls[i].dword[0] = plsq->pls[i].dword[1] = 0;
    }

    Uint32 expTime = 0;
    expTime = p[0] + p[4] + p[10]+ p[1] + TE/2 + (TE + p[4])*Necho;

    return expTime; // in  microsecond
}// end of IRCPMG



// DE-CPMG


// COSY pulse sequence generation


// Inversion recovery pulse sequence
