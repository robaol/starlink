      SUBROUTINE ADI2_INIT( STATUS )
*+
*  Name:
*     ADI2_INIT

*  Purpose:
*     Load ADI definitions required for use of FITS files

*  Language:
*     Starlink Fortran

*  Invocation:
*     CALL ADI2_INIT( STATUS )

*  Description:
*     {routine_description}

*  Arguments:
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
*     ADI Subroutine Guide : http://www.sr.bham.ac.uk/asterix-docs/Programmer/Guides/adi.html

*  Keywords:
*     package:adi, usage:private

*  Copyright:
*     Copyright (C) University of Birmingham, 1995

*  Authors:
*     DJA: David J. Allan (Jet-X, University of Birmingham)
*     {enter_new_authors_here}

*  History:
*     14 Aug 1995 (DJA):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Status:
      INTEGER 			STATUS             	! Global status

*  External References:
      EXTERNAL        		ADI2_OPEN
      EXTERNAL        		ADI2_FCREAT
      EXTERNAL        		ADI2_FTRACE
      EXTERNAL        		ADI2_FCOMIT
      EXTERNAL        		ADI2_FCLOSE
      EXTERNAL        		ADI2_NEWLNK_ARR

c      EXTERNAL        		BDI2_SETLNK

c      EXTERNAL        		EDI2_SETLNK

*  Local Variables:
      INTEGER			DID			! Dummy id (ignored)
      INTEGER			RID			! Representation id
*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Load the FITS package
      CALL ADI_REQPKG( 'fits', STATUS )

*  Locate the FITS file representation object
      CALL ADI_LOCREP( 'FITS', RID, STATUS )

      CALL ADI_DEFRCB( RID, 'CreatRtn', ADI2_FCREAT, STATUS )
      CALL ADI_DEFRCB( RID, 'OpenRtn', ADI2_OPEN, STATUS )

*  File system methods
      CALL ADI_DEFMTH( 'FileClose(_FITSfile)', ADI2_FCLOSE, DID,
     :                   STATUS )
      CALL ADI_DEFMTH( 'FileComit(_FITSfile)', ADI2_FCOMIT, DID,
     :                   STATUS )
      CALL ADI_DEFMTH( 'FileTrace(_FITSfile)', ADI2_FTRACE, DID,
     :                   STATUS )

      CALL ADI_DEFMTH( 'NewLink(_Array,_FITSfile)', ADI2_NEWLNK_ARR,
     :                   DID, STATUS )

*  Define BDI interface
c      CALL ADI_DEFMTH( 'SetLink(_BinDS,_FITSfile)', BDI2_SETLNK,
c     :                 DID, STATUS )

c      CALL ADI_DEFMTH( 'SetLink(_EventDS,_FITSfile)', EDI2_SETLNK,
c     :                 DID, STATUS )

*  Report any errors
      IF ( STATUS .NE. SAI__OK ) CALL AST_REXIT( 'ADI2_INIT', STATUS )

      END
