/*
 * noe1dseq.c
 *
 *  Created on: Nov 23, 2019
 *      Author: ysong
 */



// **************** history
/*
 * program a noe 1d seq, to saturate fluorine line, then acquire hydrogen sign by fid
 * modify a FID seq
 * Add .h file
 * Nov 2019, YS
 */


// ***************** end of history



#include "DSP28x_Project.h"                                     // Device Headerfile and Examples Include File
#include "stdlib.h"
#include <string.h>

#include "RunNMR.h"
#include "nmr.h"
#include "nmr_plsq.h"
#include "gpio_init.h"
#include "asic.h"

// NMR System Parameter settings
/* definition is in RunNMR.h
 *
*/

// NMR parameters

extern NMR_Sys_Parameters NMR_system_settings;
extern PlsSeq gPulseSeq;                                               // store the pulse seq, global

// defined in RunNMR.h
// #define dataBufferTD 1000                                        // dataBufferTD = 2600 x 16bits

extern int16   dataBuf_real[dataBufferTD];                             // real data buffer
extern int16   dataBuf_imag[dataBufferTD];                             // imaginary data buffer



/* NOE1d seq:
 * set to 1H freq, tune circuit to it, execute a train of saturation pulses
 * then switch freq to F19, switch tuning, do FID for signal
 * As a comparison, run a FID signal without saturation pulses, but keep the timing identical
 */
/*
 * generic seq:
 * RD -- train of 90 deg pulses to saturate at f2 -- wait time -- FID acq at f1
 * Use seq code 100.
 */

int Run_NMR_NOE1dFID_mcbsp(void)
{
    int ii = 0, acqPTs;                                                 // ii= index, acq points
    int DS = 0, NA;                                                         // Dummy Scan
    long Nint, Nfrac;

    // pulse seq parameters
    // phase table
    int ph1[]    = {0,2,1,3};                                               // in unit of 90 deg
    int phacq[] = {0,2,1,3};
    int phlength = 4;


//    PLL_freq_set3(NMR_system_settings.Freq*2);

//    spi_dac_MCC(NMR_system_settings.tuningcap);
//    AsicGainCtrl (NMR_system_settings.RecGain);

//    DELAY_US(10000);

    strcpy(NMR_system_settings.SEQ, "NOE1dFID");

    // parameters used in assisting the running of the seq
    Uint32  expTime;                                                    // total time for 1 run of pulse seq, obtain from the pulse seq itself
    Uint32  p[10];// = {500000,20,30,0,10,500};                              //{500000,20,30,0,10,500}


    // update freq, scan


    DS = NMR_system_settings.DS;
    NA = NMR_system_settings.NA;

    p[0]=NMR_system_settings.RD     ;                                   // RD
    p[1]=NMR_system_settings.T90    ;                                   // T90 RF pulse width
    p[2]=30                         ;                                   // amp, PL[0]
    p[3]=ph1[0]*8                   ;                                   // phase, 32 steps, to be cycled by ph1
    p[4]=NMR_system_settings.dw     ;                                   // dw time, us
    p[5]=NMR_system_settings.TD     ;

    for (ii=0; ii<p[5]; ii++) dataBuf_real[ii] = dataBuf_imag[ii] = 0;  // reset data mem to 0
    // ---------------------------------------------
    // internal loop for phase cycling and averaging

    for (ii=-DS;ii<NA;ii++)
    {
        // freq2 part of the seq

        PLL_freq_set3(NMR_system_settings.nint*2);  // use for f2
        spi_dac_MCC(NMR_system_settings.nfrac);     // use for tuningcap value
        AsicGainCtrl (NMR_system_settings.RecGain);
        // parameter form :
        // [0]  : RD,
        // [1-3]: T90, amp, ph1,
        // [4-5]: T180, ph2, P180 time and phase
        // [6-8]: TE, Necho, NPTS : echo time, and number of echoes, and number of pt per echo
        // [9] : dw
        // return the total period of time for the experiment

         p[0]=NMR_system_settings.RD     ;           // RD
         p[1]=NMR_system_settings.T90    ;           // T90 RF pulse width
         p[2]=30 ;                                   // amp, PL[0]
         p[3]=0*8                  ;                 // phase, 32 steps, to be cycled by ph1
         p[4]=p[1]                  ;               // t180, use 90 deg pulse for sat
         p[5]=p[3]                  ;               // phase for 180 pulse
         p[6]=1000                  ;              // echo spacing, 10ms
         p[7]=4                   ;               // NE
         p[8]=10                    ;               // number of pt per echo acq
         p[9]=NMR_system_settings.dw     ;          // dw time, us


        expTime = CPMG2(&gPulseSeq,p);
        // execute CPMG seq as defined above
        acqPTs = Run_NMR_Accumulate_mcbsp(&gPulseSeq, expTime, p[9],p[7]*p[8], -1);
        //DELAY_US(expTime);
        // end of Freq2

        // start Freq1 channel
        // 1H channel -- need update
        PLL_freq_set3(NMR_system_settings.Freq*2);  // use for f1
        spi_dac_MCC(NMR_system_settings.tuningcap);

        DELAY_US(1000);
        // wait time
        DELAY_US(NMR_system_settings.tau);           // 100 ms

        p[0]=1000     ;                           // RD
        p[1]=NMR_system_settings.T90    ;           // T90 RF pulse width
        p[2]=30 ;                                   // amp, PL[0]
        p[3]=ph1[0]*8                   ;           // phase, 32 steps, to be cycled by ph1
        p[4]=NMR_system_settings.dw     ;           // dw time, us
        p[5]=NMR_system_settings.TD     ;           //data point


        // update phase cycling
        if (ii<0)
            p[3]=ph1[0]*8;                                              // set the phase of the pulse, first ph1 for dummy scan
        else
            p[3]=ph1[ii % phlength]*8;                              // set the phase of the pulse

        expTime = FID2(&gPulseSeq,p);                               // recreate the seq with the proper phase
                                                                        // total time for the experiment in US
                                                                        // gPulseSeq global record of pulse seq results
                                                                        // FID2 pulse gen code
        // do NMR, ii<0 is dummy scans
        if (ii<0)
            acqPTs = Run_NMR_Accumulate_mcbsp(&gPulseSeq, expTime, p[4],p[5],  -1);   //dummy scan
        else
            acqPTs = Run_NMR_Accumulate_mcbsp(&gPulseSeq, expTime, p[4],p[5], phacq[(ii % phlength)]);
    }
    NMR_system_settings.acquiredTD = acqPTs;

    return(acqPTs);

} // end of Run_NMR_NOE1dFID_mcbsp(void)
