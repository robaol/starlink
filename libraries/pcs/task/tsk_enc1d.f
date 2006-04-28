      SUBROUTINE TASK_ENC1D ( NVALS, DVALS, STRING, STATUS )
*+
*  Name:
*     TASK_ENC1D

*  Purpose:
*     Encode a vector as a character string

*  Language:
*     Starlink Fortran 77

*  Type Of Module:
*     SUBROUTINE

*  Invocation:
*     CALL TASK_ENC1D ( NVALS, DVALS, STRING, STATUS )

*  Description:
*     Convert the given 1-D array into characters and concatenate the
*     result into a string with the ADAM syntax, that is the elements of
*     the array are separated and the whole is surrounded by [].
*     There is a routine for each type C, D, I, L, R.

*  Arguments:
*     NVALS=INTEGER (given)
*           number of values in the 1-D array
*     DVALS(NVALS)=DOUBLE PRECISION (given)
*           the array to be converted
*     STRING=CHARACTER*(*) (returned)
*           the returned character string
*     STATUS=INTEGER

*  Algorithm:
*     Call TASK_ENCND

*  Authors:
*     B.D.Kelly (REVAD::BDK)
*     {enter_new_authors_here}

*  History:
*     06-NOV-1987 (REVAD::BDK):
*        Original
*     29-APR-1989 (AAOEPP::WFL):
*        Make it generic
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE
*  Global Constants:
      INCLUDE 'SAE_PAR'
 
*  Arguments Given:
      INTEGER NVALS         ! number of values in the 1-D array
 
      DOUBLE PRECISION DVALS(NVALS) ! the array to be encoded
 
*  Arguments Returned:
      CHARACTER*(*) STRING  ! the returned character string
 
*  Status:
      INTEGER STATUS
 
*  Local Variables:
      INTEGER NDIMS         ! no of dimensions to be passed
*.
 
      IF ( STATUS .NE. SAI__OK ) RETURN
 
      NDIMS = 1
      CALL TASK_ENCND ( NDIMS, NVALS, DVALS, STRING, STATUS )
 
      END
