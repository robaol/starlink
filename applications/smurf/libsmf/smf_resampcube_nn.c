/*
*+
*  Name:
*     smf_resampcube_nn

*  Purpose:
*     Resample a supplied 3D array into a time series cube using custom 2D 
*     nearest neighbour code.

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     C function

*  Invocation:
*     void smf_resampcube_nn( smfData *data, int index, int size, dim_t nchan, 
*                             dim_t ndet, dim_t nslice, dim_t nel, dim_t nxy, 
*                             dim_t nsky, dim_t dim[3], AstMapping *ssmap, 
*                             AstSkyFrame *abskyfrm, AstMapping *iskymap, 
*                             Grp *detgrp, int moving, float *in_data, 
*                             float *out_data, int *status );

*  Arguments:
*     data = smfData * (Given)
*        Pointer to the template smfData structure.
*     index = int (Given)
*        Index of the current template within the group of templates.
*     size = int (Given)
*        Index of the last template within the group of templates.
*     nchan = dim_t (Given)
*        Number of spectral channels in template.
*     ndet = dim_t (Given)
*        Number of detectors in template.
*     nslice = dim_t (Given)
*        Number of time slices in template.
*     nel = dim_t (Given)
*        Total number of elements in template.
*     nxy = dim_t (Given)
*        Number of elements in one spatial plane of the sky cube.
*     nsky = dim_t (Given)
*        Total number of elements in the sky cube.
*     dim[ 3 ] = dim_t (Given)
*        The dimensions of the sky cube.
*     ssmap = AstMapping * (Given)
*        A Mapping that goes from template spectral grid axis (pixel axis 1)
*        to the sky cube spectral grid axis (pixel axis 3).
*     abskyfrm = AstSkyFrame * (Given)
*        A SkyFrame that specifies the coordinate system used to describe 
*        the spatial axes of the sky cube. This should represent
*        absolute sky coordinates rather than offsets even if "moving" is 
*        non-zero.
*     iskymap = AstFrameSet * (Given)
*        A Mapping from 2D sky coordinates in the sky cube to 2D
*        spatial grid coordinates in the template.
*     detgrp = Grp * (Given)
*        A Group containing the names of the detectors to be used. All
*        detectors will be used if this group is empty.
*     moving = int (Given)
*        A flag indicating if the telescope is tracking a moving object. If 
*        so, each time slice is shifted so that the position specified by 
*        TCS_AZ_BC1/2 is mapped on to the same pixel position in the
*        sky cube.
*     in_data = float * (Given)
*        The 3D data array for the input sky cube.
*     out_data = float * (Returned)
*        The 3D data array for the output time series array.
*     status = int * (Given and Returned)
*        Pointer to the inherited status.

*  Description:
*     The data array of the supplied sky cube is resampled at the
*     detector sample positions specified by the input template. The 
*     resampled values are stored in the output time series cube.
*
*     Specialised code is used that only provides Nearest Neighbour
*     spreading when pasting each input pixel value into the output cube.

*  Authors:
*     David S Berry (JAC, UClan)
*     {enter_new_authors_here}

*  History:
*     25-JAN-2008 (DSB):
*        Initial version.
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2008 Science & Technology Facilities Council.
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
#include <math.h>

/* Starlink includes */
#include "ast.h"
#include "mers.h"
#include "sae_par.h"
#include "prm_par.h"
#include "star/ndg.h"
#include "star/atl.h"

/* SMURF includes */
#include "libsmf/smf.h"

#define FUNC_NAME "smf_resampcube_nn"

void smf_resampcube_nn( smfData *data, int index, int size, dim_t nchan, 
                        dim_t ndet, dim_t nslice, dim_t nel, dim_t nxy, 
                        dim_t nsky, dim_t dim[3], AstMapping *ssmap, 
                        AstSkyFrame *abskyfrm, AstMapping *iskymap, 
                        Grp *detgrp, int moving, float *in_data, 
                        float *out_data, int *status ){

/* Local Variables */
   AstMapping *totmap = NULL;  /* WCS->GRID Mapping from template WCS FrameSet */
   const char *name = NULL;    /* Pointer to current detector name */
   dim_t timeslice_size;       /* No of detector values in one time slice */
   double *detxtemplt = NULL;  /* Work space for template X grid coords */
   double *detxskycube = NULL; /* Work space for sky cube X grid coords */
   double *detytemplt = NULL;  /* Work space for template Y grid coords */
   double *detyskycube = NULL; /* Work space for sky cube Y grid coords */
   float *ddata = NULL;        /* Pointer to start of output detector data */
   float *tdata = NULL;        /* Pointer to start of sky cube time slice data */
   int *spectab = NULL;        /* Template->sky cube channel number conversion table */
   int detok;                  /* Did the detector receive any data? */
   int found;                  /* Was current detector name found in detgrp? */
   int gxsky;                  /* Sky cube X grid index */
   int gysky;                  /* Sky cube Y grid index */
   int ichan;                  /* Output channel index */
   int idet;                   /* Detector index */
   int itime;                  /* Index of current time slice */
   int iv0;                    /* Offset for pixel in 1st sky cube spectral channel */
   smfHead *hdr = NULL;        /* Pointer to data header for this time slice */

/* Check the inherited status. */
   if( *status != SAI__OK ) return;

/* Store a pointer to the template NDFs smfHead structure. */
   hdr = data->hdr;

/* Store the number of pixels in one time slice */
   timeslice_size = ndet*nchan;

/* Use the supplied mapping to get the zero-based sky cube channel number 
   corresponding to each template channel number. */
   smf_rebincube_spectab( nchan, dim[ 2 ], ssmap, &spectab, status );
   if( !spectab ) goto L999;

/* Allocate work arrays to hold the template and sky cube grid coords for each 
   detector. */
   detxtemplt = astMalloc( ndet*sizeof( double ) );
   detytemplt = astMalloc( ndet*sizeof( double ) );
   detxskycube = astMalloc( ndet*sizeof( double ) );
   detyskycube = astMalloc( ndet*sizeof( double ) );

/* Initialise a string to point to the name of the first detector for which 
   data is to be created. */
   name = hdr->detname;

/* Fill the arrays with the grid coords of each detector. */
   for( idet = 0; idet < ndet; idet++ ) {
      detxtemplt[ idet ] = (double) idet + 1.0;
      detytemplt[ idet ] = 1.0;

/* If a group of detectors to be used was supplied, search the group for
   the name of the current detector. If not found, set the GRID coord
   bad. */
      if( detgrp ) {    
         grpIndex( name, detgrp, 1, &found, status );
         if( !found ) {
            detxtemplt[ idet ] = AST__BAD;
            detytemplt[ idet ] = AST__BAD;
         }
      }

/* Move on to the next available detector name. */
      name += strlen( name ) + 1;
   }

/* Loop round all time slices in the template NDF. */
   for( itime = 0; itime < nslice && *status == SAI__OK; itime++ ) {

/* Store a pointer to the first output data value in this time slice. */
      tdata = out_data + itime*timeslice_size;

/* Begin an AST context. Having this context within the time slice loop
   helps keep the number of AST objects in use to a minimum. */
      astBegin;

/* Get a Mapping from the spatial GRID axes in the template to the spatial 
   GRID axes in the sky cube for the current time slice. Note this has 
   to be done first since it stores details of the current time slice 
   in the "smfHead" structure inside "data", and this is needed by
   subsequent functions. */
      totmap = smf_rebin_totmap( data, itime, abskyfrm, iskymap, moving, 
				 status );
      if( !totmap ) break;

/* Use this Mapping to get the sky cube spatial grid coords for each
   template detector. */
      astTran2( totmap, ndet, detxtemplt, detytemplt, 1, detxskycube, 
                detyskycube );

/* Loop round each detector, obtaining its output value from the sky cube. */
      for( idet = 0; idet < ndet; idet++ ) {

/* Get a pointer to the start of the output spectrum data. */
         ddata = tdata + idet*nchan;

/* Check the detector has a valid position in sky cube grid coords */
         detok = 0;
         if( detxskycube[ idet ] != AST__BAD && detyskycube[ idet ] != AST__BAD ){

/* Find the closest sky cube pixel and check it is within the bounds of the
   sky cube. */
            gxsky = floor( detxskycube[ idet ] + 0.5 );
            gysky = floor( detyskycube[ idet ] + 0.5 );
            if( gxsky >= 1 && gxsky <= dim[ 0 ] &&
                gysky >= 1 && gysky <= dim[ 1 ] ) {

/* Get the offset of the sky cube array element that corresponds to this
   pixel in the first spectral channel. */
               iv0 = ( gysky - 1 )*dim[ 0 ] + ( gxsky - 1 );

/* Get a pointer to the start of the output spectrum data and copy the 
   sky cube spectrum into it. */
               ddata = tdata + idet*nchan;
               smf_resampcube_copy( nchan, nsky, spectab, iv0, nxy, 
                                    ddata, in_data, status );
               detok = 1;
            }
         }

/* If the detector did not receive any data, fill it with bad values. */
         if( ! detok ) {
            for( ichan = 0; ichan < nchan; ichan++ ) {
               ddata[ ichan ] = VAL__BADR;
            }
         }
      }

/* End the AST context. */
      astEnd;
   }

/* Free non-static resources. */
L999:;
   spectab = astFree( spectab );
   detxtemplt = astFree( detxtemplt );
   detytemplt = astFree( detytemplt );
   detxskycube = astFree( detxskycube );
   detyskycube = astFree( detyskycube );

}
