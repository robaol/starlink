*+  TASK_ENC0I - encode a value as a character string
      SUBROUTINE TASK_ENC0I ( IVAL, STRING, STATUS )
*    Description :
*     Convert the given value of type INTEGER into a character
*     string and return it in STRING.
*     A routine exists for each type C, D, L, I, R.
*    Invocation :
*     CALL TASK_ENC0I ( IVAL, STRING, STATUS )
*    Parameters :
*     IVAL=INTEGER (given)
*           the value to be encoded
*     STRING=CHARACTER*(*) (returned)
*           the returned character string
*     STATUS=INTEGER
*    Method :
*     Use appropriate CHR routine
*    Deficiencies :
*     <description of any deficiencies>
*    Bugs :
*     <description of any "bugs" which have not been fixed>
*    Authors :
*     B.D.Kelly (REVAD::BDK)
*    History :
*     06.11.1987:  original (REVAD::BDK)
*     29.04.1989:  make it generic (AAOEPP::WFL)
*      4.10.1992:  use CHR (RLVAD::AJC)
*    endhistory
*    Type Definitions :
      IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'
 
*    Import :
      INTEGER IVAL         ! the value to be encoded
 
*    Export :
      CHARACTER*(*) STRING  ! the returned character string
 
*    Status :
      INTEGER STATUS
 
*    Local variables :
      INTEGER NCHAR         ! length of encoded string
*-
 
      IF ( STATUS .NE. SAI__OK ) RETURN
 
      CALL CHR_ITOC( IVAL, STRING, NCHAR )
 
      END
