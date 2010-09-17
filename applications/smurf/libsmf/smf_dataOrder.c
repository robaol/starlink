/*
*+
*  Name:
*     smf_dataOrder

*  Purpose:
*     Set the data/variance/quality array order for a smfData

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     C function

*  Invocation:
*     waschanged = smf_dataOrder( smfData *data, int isTordered, *status );

*  Arguments:
*     data = smfData* (Given and Returned)
*        Group of input data files
*     isTordered = int (Given)
*        If 0, ensure data is ordered by bolometer. If 1 ensure data is
*        ordered by time slice (default ICD ordering)
*     status = int* (Given and Returned)
*        Pointer to global status.

*  Description:
*     This function is used to change the ordering of
*     DATA/VARIANCE/QUALITY arrays associated with a smfData. Normally
*     SCUBA-2 data is stored as time-ordered data; each 40x32 element
*     chunk of contiguous memory contains bolometer data from the same
*     time slice. This array ordering is impractical for time-domain
*     operations such as filtering. In these cases it is preferable to
*     have all of the data from a single bolometer stored in a
*     contiguous chunk of memory (bolometer ordered).  Use this
*     function to change between the two ordering schemes. Note that
*     this routine first checks the current array order before doing
*     anything; if the requested array order matches the current order
*     it simply returns. If the smfData was memory mapped then the
*     routine changes the data order in-place (slightly
*     slower). Otherwise a new buffer is allocated with the re-ordered
*     data, and the old buffer is free'd. If flags set to
*     SMF__NOCREATE_FILE and a file is associated with the data, don't
*     write anything (workaround for cases where it was opened
*     read-only). The pointing LUT will only be re-ordered if it is
*     already open (e.g. from a previous call to smf_open_mapcoord).

*  Returned Value:
*     waschanged = int
*        True if the data were re-ordered. False otherwise.

*  Authors:
*     EC: Edward Chapin (UBC)
*     {enter_new_authors_here}

*  History:
*     2007-09-13 (EC):
*        Initial version.
*     2007-10-31 (EC):
*        - changed index multiplications to successive additions in tight loops
*        - re-order pointing LUT if it exists
*     2007-11-28 (EC):
*        Update FITS keyword TORDERED when data order is modified
*     2007-12-14 (EC):
*        - fixed LUT re-ordering pointer bug
*        - extra file existence checking if writing TORDERED FITS entry
*     2007-12-18 (AGG):
*        Update to use new smf_free behaviour
*     2008-01-25 (EC):
*        -removed setting of TORDERED keyword from FITS header
*        -always set data dimensions (moved out of loop)
*     2008-02-08 (EC):
*        -Fixed dtype for QUALITY -- SMF__UBYTE instead of SMF__USHORT
*     2009-01-06 (EC):
*        Stride-ify
*     2009-09-29 (TIMJ):
*        Handle pixel origin reordering
*     2010-05-20 (TIMJ):
*        Return a boolean indicating whether the data were reordered or not.
*     2010-06-14 (TIMJ):
*        Refactor logic for new location of quality pointer.
*     2010-06-21 (TIMJ):
*        Add _UWORD support.
*     2010-07-07 (TIMJ):
*        Reorder sidequal
*     2010-08-31 (EC):
*        Move private smf__dataOrder_array into public smf_dataOrder_array

*  Notes:
*     Nothing is done about the FITS channels or WCS information stored in
*     the header, so anything that depends on them will get confused by
*     bolo-ordered data produced with this routine.

*  Copyright:
*     Copyright (C) 2009-2010 Science & Technology Facilities Council.
*     Copyright (C) 2005-2009 University of British Columbia.
*     Copyright (C) 2005-2006 Particle Physics and Astronomy Research Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 3 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public
*     License along with this program; if not, write to the Free
*     Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
*     MA 02111-1307, USA

*  Bugs:
*     {note_any_bugs_here}
*-
*/

#include <stdio.h>

/* Starlink includes */
#include "mers.h"
#include "sae_par.h"
#include "star/ndg.h"
#include "prm_par.h"
#include "par_par.h"

/* SMURF includes */
#include "libsmf/smf.h"
#include "libsmf/smf_err.h"

/* Other includes */

#define FUNC_NAME "smf_dataOrder"

int smf_dataOrder( smfData *data, int isTordered, int *status ) {

  /* Local Variables */
  size_t bstr1;                 /* bolometer index stride input */
  size_t bstr2;                 /* bolometer index stride output */
  dim_t i;                      /* loop counter */
  int inPlace=0;                /* If set change array in-place */
  dim_t nbolo;                  /* Number of bolometers */
  dim_t ndata;                  /* Number of data points */
  dim_t newdims[3];             /* Size of each dimension new buffer */
  int newlbnd[3];               /* New pixel origin */
  dim_t ntslice;                /* Number of time slices */
  size_t tstr1;                 /* time index stride input */
  size_t tstr2;                 /* time index stride output */
  int waschanged = 0;           /* did we chagne the order? */

  /* Main routine */
  if (*status != SAI__OK) return waschanged;

  /* Check for valid isTordered */
  if( (isTordered != 0) && (isTordered != 1) ) {
    *status = SAI__ERROR;
    msgSeti("ISTORDERED",isTordered);
    errRep( "", FUNC_NAME ": Invalid isTordered (0/1): ^ISTORDERED", status);
    return waschanged;
  }

  /* Check for a valid data */
  if( !data ) {
    *status = SAI__ERROR;
    errRep( "", FUNC_NAME ": NULL data supplied", status);
    return waschanged;
  }

  /* If value of isTordered matches current value in smfData return */
  if( data->isTordered == isTordered ) return waschanged;

  /* Make sure we're looking at 3-dimensions of bolo data */
  if( data->ndims != 3 ) {
    *status = SMF__WDIM;
    msgSeti("NDIMS",data->ndims);
    errRep( "", FUNC_NAME
           ": Don't know how to handle ^NDIMS dimensions, should be 3.",
            status);
    return waschanged;
  }

  /* we are going to change */
  waschanged = 1;

  /* inPlace=1 if smfData was mapped! */
  if( data->file && (data->file->fd || data->file->ndfid) ) {
    inPlace = 1;
  }

  /* Calculate input data dimensions (before changing order) */
  smf_get_dims( data, NULL, NULL, &nbolo, &ntslice, &ndata, &bstr1, &tstr1,
                status);

  /* What will the dimensions/strides be in the newly-ordered array? */
  if( isTordered ) {
    newdims[0] = (data->dims)[1];
    newdims[1] = (data->dims)[2];
    newdims[2] = (data->dims)[0];
    newlbnd[0] = (data->lbnd)[1];
    newlbnd[1] = (data->lbnd)[2];
    newlbnd[2] = (data->lbnd)[0];
    bstr2 = 1;
    tstr2 = nbolo;
  } else {
    newdims[0] = (data->dims)[2];
    newdims[1] = (data->dims)[0];
    newdims[2] = (data->dims)[1];
    newlbnd[0] = (data->lbnd)[2];
    newlbnd[1] = (data->lbnd)[0];
    newlbnd[2] = (data->lbnd)[1];
    bstr2 = ntslice;
    tstr2 = 1;
  }

  /* Loop over elements of data->ptr and re-form arrays */
  for( i=0; i<2; i++ ) {
    data->pntr[i] = smf_dataOrder_array( data->pntr[i], data->dtype, ndata,
                                         ntslice, nbolo, tstr1, bstr1, tstr2,
                                         bstr2, inPlace, 1, status );
  }

  /* And Quality */
  data->qual = smf_dataOrder_array( data->qual, SMF__QUALTYPE, ndata,
                                    ntslice, nbolo, tstr1, bstr1, tstr2,
                                    bstr2, inPlace, 1, status );

  /* If NDF associated with data, modify dimensions of the data */
  if( data->file && (data->file->ndfid != NDF__NOID) ) {
    msgOutif(MSG__DEBUG, " ", FUNC_NAME
             ": Warning - current implementation does not modify NDF "
             "dimensions to match re-ordered data array", status);
  }

  /* If there is a LUT re-order it here */
  data->lut = smf_dataOrder_array( data->lut, SMF__INTEGER, ndata, ntslice,
                                   nbolo, tstr1, bstr1, tstr2, bstr2, inPlace,
                                   1, status );

  /* Set the new dimensions in the smfData */
  if( *status == SAI__OK ) {
    memcpy( data->dims, newdims, 3*sizeof(*newdims) );
    memcpy( data->lbnd, newlbnd, 3*sizeof(*newlbnd) );
    data->isTordered = isTordered;
  }

  /* Force any external quality to same ordering */
  if (data->sidequal) {
    int qchanged = 0;
    qchanged = smf_dataOrder( data->sidequal, isTordered, status );
    /* and indicate if we changed anything (but not if we did not) */
    if (qchanged) waschanged = qchanged;
  }

  return waschanged;
}

