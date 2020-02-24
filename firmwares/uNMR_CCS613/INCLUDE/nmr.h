/*
 * nmr.h
 *
 *  Created on: Aug 1, 2016
 *      Author: mccowan1
 */
//###########################################################################
// Revision History:
//
//
//
//
//
//###########################################################################

#ifndef INCLUDE_NMR_H_
#define INCLUDE_NMR_H_

#include "typeDefs.h"
#include "nmr_plsq.h"

void ResetNMR (void);
void InitNMR( void );
void DlPlSeq(PlsSeq* plsq);

void EN_NMR_mode();

void EN_Tuning_mode();



#endif /* INCLUDE_NMR_H_ */
