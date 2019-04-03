#include "sae_par.h"
#include "dat_par.h"
#include "ndf1.h"
#include "ndf.h"
#include "mers.h"

void ndfNew_( const char *ftype, int ndim, const hdsdim lbnd[],
             const hdsdim ubnd[], int *place, int *indf, int *status ){
/*
*+
*  Name:
*     ndfNew

*  Purpose:
*     Create a new simple NDF.

*  Synopsis:
*     void ndfNew( const char *ftype, int ndim, const hdsdim lbnd[],
*                  const hdsdim ubnd[], int *place, int *indf, int *status )

*  Description:
*     This function creates a new simple NDF and returns an identifier for
*     it. The NDF may subsequently be manipulated with the NDF_ functions.

*  Parameters:
*     ftype
*        Pointer to a null terminated string holding the full type of the
*        NDF's DATA component (e.g. "_REAL" or "COMPLEX_INTEGER").
*     ndim
*        Number of NDF dimensions.
*     lbnd
*        Lower pixel-index bounds of the NDF.
*     ubnd
*        Upper pixel-index bounds of the NDF.
*     *place
*        An NDF placeholder (e.g. generated by the ndfPlace function) which
*        indicates the position in the data system where the new NDF will
*        reside. The placeholder is annulled by this function, and a value
*        of NDF__NOPL will be returned (as defined in the include file
*        "ndf.h").
*     *indf
*        Returned holding the identifier for the new NDF.
*     *status
*        The global status.

*  Notes:
*     -  This function creates a "simple" NDF, i.e. one whose array
*     components will be stored in "simple" form by default (see SGP/38).
*     -  The full data type of the DATA component is specified via the
*     "ftype" parameter and the data type of the VARIANCE component
*     defaults to the same value. These data types may be set individually
*     with the ndfStype function if required.
*     -  If this function is called with "status" set, then a value of
*     NDF__NOID will be returned for the "indf" parameter, although no
*     further processing will occur. The same value will also be returned
*     if the function should fail for any reason. In either event, the
*     placeholder will still be annulled. The NDF__NOID constant is defined
*     in the header file "ndf.h".

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
   NdfACB *acb;          /* Pointer to NDF entry in the ACB */
   NdfPCB *pcb;          /* Pointer to placeholder entry in the PCB */
   char type[ NDF__SZTYP + 1 ];    /* Numeric data type */
   int cmplx;            /* Whether the data type is complex */
   int erase;            /* Whether to erase placeholder object */
   int tstat;            /* Temporary status variable */

/* Ensure the NDF library has been initialised. */
   NDF_INIT( status );

/* Set an initial value for the "indf" parameter. */
   *indf = NDF__NOID;

/* Save the "status" value and mark the error stack. */
   tstat = *status;
   errMark();

/* Import the NDF placeholder, converting it to a PCB index. */
   *status = SAI__OK;
   pcb = NULL;
   ndf1Imppl( *place, &pcb, status );

/* If there has been no error at all so far, then check the data type
   and bounds information for validity. */
   if( ( *status == SAI__OK ) && ( tstat == SAI__OK ) ) {
      ndf1Chftp( ftype, type, sizeof( type ), &cmplx, status );
      ndf1Vbnd( ndim, lbnd, ubnd, status );
      if( *status == SAI__OK ) {

/* Create a new simple NDF in place of the placeholder object,
   obtaining an ACB entry which refers to it. */
         ndf1Dcre( ftype, ndim, lbnd, ubnd, pcb, &acb, status );

/* Export an identifier for the NDF. */
         *indf = ndf1Expid( ( NdfObject * ) acb, status );

/* If an error occurred, then annul any ACB entry which may have been
   acquired. */
         if( *status != SAI__OK ) ndf1Anl( &acb, status );
      }
   }

/* Annul the placeholder, erasing the associated object if any error has
   occurred. */
   if( pcb ) {
      erase = ( ( *status != SAI__OK ) || ( tstat != SAI__OK ) );
      ndf1Annpl( erase, &pcb, status );
   }

/* Reset the "place" parameter. */
   *place = NDF__NOPL;

/* Annul any error if "status" was previously bad, otherwise let the new
   error report stand. */
   if( *status != SAI__OK ) {
      if( tstat != SAI__OK ) {
         errAnnul( status );
         *status = tstat;

/* If appropriate, report the error context and call the error tracing
   function. */
      } else {
         *indf = NDF__NOID;
         errRep( " ", "ndfNew: Error creating a new simple NDF.", status );
         ndf1Trace( "ndfNew", status );
      }
   } else {
      *status = tstat;
   }

/* Release error stack. */
   errRlse();

/* Restablish the original AST status pointer */
   NDF_FINAL

}

