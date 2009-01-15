#if !defined( KAPLIBS_INCLUDED )  /* Include this file only once */
#define KAPLIBS_INCLUDED
/*
*+
*  Name:
*     kaplibs.h

*  Purpose:
*     Define the C interface to the KAPLIBS library.

*  Description:
*     This module defines the C interface to the functions of the KAPLIBS
*     library. The file kaplibs.c contains C wrappers for the Fortran 
*     KAPLIBS routines.

*  Notes:
*     - Given the size of the KAPLIBS library, providing a complete C
*     interface is probably not worth the effort. Instead, I suggest that 
*     people who want to use KAPLIBS from C extend this file (and
*     kaplibs.c) to include any functions which they need but which are
*     not already included.

*  Copyright:
*     Copyright (C) 2005, 2006 Particle Physics & Astronomy Research Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*     
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*     
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     DSB: David .S. Berry
*     TIMJ: Tim Jenness (JAC, Hawaii)

*  History:
*     29-SEP-2005 (DSB):
*        Original version.
*     03-NOV-2005 (TIMJ):
*        GRP interface now uses struct
*     7-MAR-2006 (DSB):
*        Added KPG1_RGNDF and KPG1_WGNDF.
*     25-APR-2006 (TIMJ):
*        Add kpgPtfts
*     03-JUL-2006 (TIMJ):
*        Add kpgStatd
*     10-JUL-2006 (DSB):
*        Add kpg1_wwrt and kpg1_wread.
*     14-AUG-2006 (DSB):
*        Added kpg1_mxmnd, kpg1_mxmnr and kpg1_mxmni.
*     29-NOV-2006 (DSB):
*        Added kpg1Gtaxv.
*     5-FEB-2007 (DSB):
*        Added kpg1_gtwcs.
*     7-FEB-2007 (DSB):
*        Added kpg1_medur.
*     22-MAR-2007 (DSB):
*        Added kpg1_gilst.
*     7-MAR-2008 (DSB):
*        Added IRQ constants.
*     15-JUL-2008 (TIMJ):
*        const and size_t to match Grp
*-
*/

#include "ast.h"
#include "star/grp.h"
#include "star/hds.h"
#include "star/hds_fortran.h"


/* Macros */
/* ====== */

/* An illegal IRQ_ identifier value. This value can sometimes be
   specified by an application in place of an IRQ_ identifier in order
   to supress some operation. */
#define IRQ__NOID 0

/* The name of the structure holding the quality names information.  */
#define IRQ__QINAM QUALITY_NAMES

/* The type of the structure holding the quality names information. */
#define IRQ__QITYP QUALITY_NAMES

/* Maximum length of descriptive comments stored with each quality name. */
#define IRQ__SZCOM 50 

/* Maximum length of a quality expression. */
#define IRQ__SZQEX 255 

/* Maximum length of a quality name. */
#define IRQ__SZQNM 15 



/* Type definitions */
/* ================ */

/* A structure used to pass a group of five HDS locators to and from IRQ
   functions. */

typedef struct IRQLocs {
   HDSLoc *loc[ 5 ];
} IRQLocs;



/* Prototypes for public functions */
/* =============================== */

void kpg1Asget( int, int, int, int, int, int *, int *, int *, AstFrameSet **, int * );
void kpg1Fillr( float, int, float *, int * );
void kpg1Gausr( float, int, int, float, int, int, int, int, float *, float *, int *, float *, float *, float *, int * );
void kpg1Gtgrp( const char *, Grp **, size_t*, int *);
void kpg1Gtwcs( int, AstFrameSet **, int * );
void kpg1Kygrp( AstKeyMap *, Grp **, int * );
void kpg1Kymap( const Grp *, AstKeyMap **, int * );
void kpg1Manir( int, int *, float *, int, int *, int *, int *, int *, float *, int * );
void kpg1Pseed( int * );
void kpg1Rgndf( const char *, size_t, size_t, const char *, Grp **, size_t *, int * );
void kpg1Wgndf( const char *, const Grp *, size_t, size_t, const char *, Grp **, size_t *, int * );
void kpg1Wrlst( const char *, int, int, int, double *, int, AstFrameSet *, const char *, int, int *, int, int * );
void kpg1Wrtab( const char *, int, int, int, double *, int, AstFrameSet *, const char *, int, int *, Grp *, Grp *, int, int * );

void irqAddqn( const IRQLocs *, const char *, int, const char *, int * );
void irqDelet( int, int * );
void irqFind( int, IRQLocs **, char[DAT__SZNAM + 1], int * );
void irqGetqn( const IRQLocs *, const char *, int *, int *, int *, char *, int, int * );
void irqNew( int, const char *, IRQLocs **, int * );
void irqRbit( const IRQLocs *, const char *, int *, int * );
void irqRlse( IRQLocs **, int * );
void irqRwqn( const IRQLocs *, const char *, int, int, int *, int * );
void irqSetqm( const IRQLocs *, int, const char *, int, float *, int *, int * );
void irqFxbit( const IRQLocs *, const char *, int, int *, int * );

int kpgGtfts( int, AstFitsChan ** fchan, int * status );
int kpgPtfts( int, const AstFitsChan * fchan, int * status );

void kpgStatd( int, int, const double[], int, const float[], int *, int *, 
               double *, int *, double *, double *, double *, double *, 
               int *, int *, double *, int *, double *, double *, double *, 
               double * , int * );

void kpgStati( int, int, const int[], int, const float[], int *, int *, 
               double *, int *, double *, double *, double *, double *, 
               int *, int *, double *, int *, double *, double *, double *, 
               double * , int * );

void kpg1Wwrt( AstObject *, const char *, const HDSLoc *, int * );
void kpg1Wread( const HDSLoc *, const char *, AstObject **, int * );
void kpg1Mxmnr( int, int, float *, int *, float *, float *, int *, int *, int * );
void kpg1Mxmnd( int, int, double *, int *, double *, double *, int *, int *, int * );
void kpg1Mxmni( int, int, int *, int *, int *, int *, int *, int *, int * );
void kpg1Medud( int, int, double *, double *, int *, int * );
void kpg1Medur( int, int, float *, float *, int *, int * );
void kpg1Opgrd( int, const double[], int, double *, double *, int * );
void kpg1Gtaxv( const char *, int, int, AstFrame *, int, double *, int *, int * );
void kpg1Gilst( int, int, int, const char *, int *, int *, int *, int * );
void kpg1Asffr( AstFrameSet *, const char *, int *, int * );
void kpg1Datcp( const HDSLoc *, HDSLoc *, const char *, int * );
void kpg1Hdsky( const HDSLoc *, AstKeyMap *, int, int, int * );
void kpg1Kyhds( AstKeyMap *, const int *, int, int, HDSLoc *, int * );
void kpg1Ghstd( int, int, const double *, int, int, double *, double *, int *, int * );
void kpg1Ghstr( int, int, const float *, int, int, float *, float *, int *, int * );
void kpg1Hsstp( int, const int *, double, double, double *, double *, double *, double *, int * );
void fts1Astwn( AstFitsChan *, int, int * );
void kpg1Ky2hd( AstKeyMap *, HDSLoc *, int * );

#endif
