#include "sae_par.h"
#include "dat_par.h"
#include "ndf1.h"
#include "ndf_err.h"
#include <string.h>
#include "star/util.h"
#include "mers.h"

void ndf1Qma( size_t el, const unsigned char qual[], unsigned char badbit,
              const char *type, int npntr, void *pntr[], int *bad,
              int *status ){
/*
*+
*  Name:
*     ndf1Qma

*  Purpose:
*     Perform quality masking on vectorised arrays.

*  Synopsis:
*     void ndf1Qma( size_t el, const unsigned char qual[],
*                   unsigned char badbit, const char *type, int npntr,
*                   void *pntr[], int *bad, int *status )

*  Description:
*     This function converts a vectorised quality array "qual" into a set
*     of "bad pixel" flags which are inserted into up to 4 matching
*     vectorised arrays of any numeric data type.  This is done by
*     performing a bit-wise AND operation between elements of the "qual"
*     array and the bitmask "badbit". Where the result of this operation is
*     non-zero, the corresponding elements of the vectorised arrays are set
*     to the appropriate "bad" value.  Other array elements are unchanged.
*     A logical value "bad" is also returned indicating whether any "bad"
*     pixels were actually generated by this quality masking process. The
*     arrays to be processed are passed to this function by pointer.

*  Parameters:
*     el
*        The number of elements to process in each vectorised array.
*     qual
*        The quality array. The supplied "qual" array should have at least
*        "el" elements.
*     badbit
*        The bad-bits mask to be applied to the quality array.
*     type
*        Pointer to a null terminated string holding the data type of the
*        arrays to be processed; an HDS primitive numeric type string (case
*        insensitive).
*     npntr
*        Number of arrays to be processed in the range 1 to 4. The function
*        will return without action if this value is out of range.
*     pntr
*        The first "npntr" elements of this array should contain pointers
*        to the vectorised arrays to be processed. The supplied "pntr"
*        array should have at least "4" elements.
*     *bad
*        Returned holding the whether any bad pixels were generated as a
*        result of the quality masking process.
*     *status
*        The global status.

*  Copyright:
*     Copyright (C) 2018 East Asian Observatory
*     All rights reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or modify
*     it under the terms of the GNU General Public License as published by
*     the Free Software Foundation; either version 2 of the License, or (at
*     your option) any later version.
*
*     This program is distributed in the hope that it will be useful,but
*     WITHOUT ANY WARRANTY; without even the implied warranty of
*     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
*     General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 51 Franklin Street,Fifth Floor, Boston, MA
*     02110-1301, USA

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK)
*     DSB: David S. Berry (EAO)

*  History:
*     xxx (DSB):
*        Original version, based on equivalent Fortran function by RFWS.

*-
*/

/* Local Variables: */
   char utype[ NDF__SZTYP + 1 ];   /* Upper case version of TYPE */
   int i;                /* Loop counter */
   int typok;            /* Whether the TYPE argument is valid */

/* Check inherited global status. */
   if( *status != SAI__OK ) return;

/* Ensure elements of "pntr" that are not of interest to the caller
   contain safe values. */
   for( i = npntr; i < 4; i++ ) pntr[ i ] = NULL;

/* If the supplied string is not too long, convert it to upper case. */
   typok =  ( strlen(type) < sizeof( utype ) );
   if( typok ) {
      astChrCase( type, utype, 1, sizeof( utype ) );

/* Compare the data type with each permitted value in turn, calling the
   appropriate function to perform quality masking. */

/* ...byte. */
      if( !strcmp( utype, "_BYTE" ) ) {
         ndf1QmaB( el, qual, badbit, npntr, pntr[ 0 ], pntr[ 1 ],
                   pntr[ 2 ], pntr[ 3 ], bad, status );

/* ...unsigned byte. */
      } else if( !strcmp( utype, "_UBYTE" ) ) {
         ndf1QmaUB( el, qual, badbit, npntr, pntr[ 0 ], pntr[ 1 ],
                    pntr[ 2 ], pntr[ 3 ], bad, status );

/* ...double precision. */
      } else if( !strcmp( utype, "_DOUBLE" ) ) {
         ndf1QmaD( el, qual, badbit, npntr, pntr[ 0 ], pntr[ 1 ],
                   pntr[ 2 ], pntr[ 3 ], bad, status );

/* ...integer. */
      } else if( !strcmp( utype, "_INTEGER" ) ) {
         ndf1QmaI( el, qual, badbit, npntr, pntr[ 0 ], pntr[ 1 ],
                   pntr[ 2 ], pntr[ 3 ], bad, status );

/* ...real. */
      } else if( !strcmp( utype, "_REAL" ) ) {
         ndf1QmaF( el, qual, badbit, npntr, pntr[ 0 ], pntr[ 1 ],
                   pntr[ 2 ], pntr[ 3 ], bad, status );

/* ...word. */
      } else if( !strcmp( utype, "_WORD" ) ) {
         ndf1QmaW( el, qual, badbit, npntr, pntr[ 0 ], pntr[ 1 ],
                   pntr[ 2 ], pntr[ 3 ], bad, status );

/* ...unsigned word. */
      } else if( !strcmp( utype, "_UWORD" ) ) {
         ndf1QmaUW( el, qual, badbit, npntr, pntr[ 0 ], pntr[ 1 ],
                    pntr[ 2 ], pntr[ 3 ], bad, status );

/* ...64-bit integer. */
      } else if( !strcmp( utype, "_INT64" ) ) {
         ndf1QmaK( el, qual, badbit, npntr, pntr[ 0 ], pntr[ 1 ],
                   pntr[ 2 ], pntr[ 3 ], bad, status );

/* Note if the data type was not recognised. */
      } else {
         typok = 0;
      }
   }

/* If the "type" parameter is not valid, then report an error. */
   if( *status == SAI__OK ) {
      if( !typok ) {
         *status = NDF__FATIN;
         msgSetc( "ROUTINE", "ndf1Qma" );
         msgSetc( "BADTYPE", type );
         errRep( " ", "Function ^ROUTINE called with an invalid TYPE "
                 "parameter of '^BADTYPE' (internal programming error).",
                 status );
      }
   }

/* Call error tracing function and exit. */
   if( *status != SAI__OK ) ndf1Trace( "ndf1Qma", status );

}

