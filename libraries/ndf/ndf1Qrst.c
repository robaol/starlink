#include "sae_par.h"
#include "dat_par.h"
#include "ndf1.h"
#include "ndf_err.h"
#include "mers.h"

void ndf1Qrst( NdfACB *acb, int *status ){
/*
*+
*  Name:
*     ndf1Qrst

*  Purpose:
*     Reset the quality component of an NDF.

*  Synopsis:
*     void ndf1Qrst( NdfACB *acb, int *status )

*  Description:
*     This function sets the quality component of an NDF into the
*     "undefined" state. No action is taken if it is already in this state
*     or if the specified NDF is not a base NDF.  The NDF is identified by
*     its ACB entry.

*  Parameters:
*     acb
*        Pointer to the NDF's ACB entry.
*     *status
*        The global status.

*  Notes:
*     -  Resetting this component involves the deletion of the associated
*     array (if it exists).

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
   NdfDCB *dcb;          /* Pointer to data object entry in the DCB */
   int valid;            /* Whether quality array exists */

/* Check inherited global status. */
   if( *status != SAI__OK ) return;

/* Ensure that quality information is available in the DCB and ACB. */
   ndf1Qimp( acb, status );
   if( *status == SAI__OK ) {

/* Obtain an index to the data object entry in the DCB. */
      dcb = acb->dcb;

/* Check that the quality component is not mapped through the current
   ACB entry. Report an error if it is. */
      if( acb->qmap ) {
         *status = NDF__ISMAP;
         ndf1Amsg( "NDF", acb );
         errRep( " ", "The quality component in the NDF structure ^NDF is "
                 "already mapped for access through the specified "
                 "identifier (possible programming error).", status );

/* Only take further action if this is a base NDF.  Check that the
   quality component is not mapped at all. Report an error if it is. */
      } else if( !acb->cut ) {
         if( dcb->nqmap != 0 ) {
            *status = NDF__ISMAP;
            ndf1Dmsg( "NDF", dcb );
            errRep( " ", "The quality component in the NDF structure ^NDF "
                    "is already mapped for access through another "
                    "identifier (possible programming error).", status );

/* See if the DCB quality array identifier is valid. If not, then the
   quality component is already undefined. */
         } else {
            valid = aryValid( dcb->qid, status );
            if( *status == SAI__OK ) {

/* If it is defined, then obtain the quality array storage form, which
   may have changed since it was created. Save this as the default for
   use if the array is re-created. */
               if( valid ) {
                  aryForm( dcb->qid, dcb->qfrm, status );

/* Delete the quality array. Note that all identifiers referring to it
   (e.g. those in the ACB) thereby become invalid. */
                  aryDelet( &dcb->qid, status );
               }
            }
         }
      }
   }

/* Call error tracing function and exit. */
   if( *status != SAI__OK ) ndf1Trace( "ndf1Qrst", status );

}

