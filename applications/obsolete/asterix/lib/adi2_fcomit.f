      SUBROUTINE ADI2_FCOMIT( FID, STATUS )
*+
*  Name:
*     ADI2_FCOMIT

*  Purpose:
*     Commit buffer changes to a FITSfile object

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL ADI2_FCOMIT( FID, STATUS )

*  Description:
*     Commit any changes to keywords or data to the FITS file on disk. The
*     file is not closed.

*  Arguments:
*     FID = INTEGER (given)
*        ADI identifier of the FITSfile object
*     STATUS = INTEGER (given and returned)
*        The global status.

*  Examples:
*     {routine_example_text}
*        {routine_example_description}

*  Pitfalls:
*     {pitfall_description}...

*  Notes:
*     {routine_notes}...

*  Prior Requirements:
*     {routine_prior_requirements}...

*  Side Effects:
*     {routine_side_effects}...

*  Algorithm:
*     {algorithm_description}...

*  Accuracy:
*     {routine_accuracy}

*  Timing:
*     {routine_timing}

*  External Routines Used:
*     {name_of_facility_or_package}:
*        {routine_used}...

*  Implementation Deficiencies:
*     {routine_deficiencies}...

*  References:
*     ADI Subroutine Guide : http://www.sr.bham.ac.uk:8080/asterix-docs/Programmer/Guides/adi.html

*  Keywords:
*     package:adi, usage:private

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     2 Feb 1995 (DJA):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'ADI_PAR'

*  Arguments Given:
      INTEGER			FID			! FITSfile identifier

*  Status:
      INTEGER 			STATUS             	! Global status

*  Local Variables:
      CHARACTER*132		CMT			! Keyword comment

      INTEGER			FSTAT			! FITSIO status
      INTEGER			LUN			! Logical unit number
      INTEGER			NAXES(ADI__MXDIM)	! Dimensions
      INTEGER			NAXIS			! Dimensionality
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Extract logical unit
      CALL ADI_CGET0I( FID, '.LUN', LUN, STATUS )

*  Primary HDU
      CALL ADI2_GKEY0I( FID, ' ', 'NAXIS', .TRUE., .FALSE.,
     :                  NAXIS, CMT, STATUS )

*  If NAXIS not present then write a null header
      IF ( STATUS .NE. SAI__OK ) THEN
        CALL ERR_ANNUL( STATUS )
        NAXIS = 0
      END IF

*  Define the header
      CALL FTPHPR( LUN, .TRUE., 8, NAXIS, NAXES, 0, 1, .TRUE., STATUS )
      CALL FTRDEF( LUN, STATUS )
      print *,'Committing changes to ',lun

*  Write the other keywords

*  Trap bad close status
      IF ( FSTAT .NE. 0 ) THEN
        CALL ADI2_FITERP( FSTAT, STATUS )
      END IF

*  Report any errors
      IF ( STATUS .NE. SAI__OK ) CALL AST_REXIT( 'ADI2_FCOMIT', STATUS )

      END
