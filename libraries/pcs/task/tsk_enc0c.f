*+  TASK_ENC0C - encode a value as a character string
      SUBROUTINE TASK_ENC0C ( CVAL, STRING, STATUS )
*    Description :
*     Convert the given value of type CHARACTER*(*) into a character
*     string and return it in STRING.
*     A routine exists for each type C, D, L, I, R.
*    Invocation :
*     CALL TASK_ENC0C ( CVAL, STRING, STATUS )
*    Parameters :
*     CVAL=CHARACTER*(*) (given)
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
      CHARACTER*(*) CVAL         ! the value to be encoded
 
*    Export :
      CHARACTER*(*) STRING  ! the returned character string
 
*    Status :
      INTEGER STATUS
 
*    Local variables :
      INTEGER NCHAR         ! length of encoded string
*-
 
      IF ( STATUS .NE. SAI__OK ) RETURN
 
      CALL CHR_CTOC( CVAL, STRING, NCHAR )
 
      END
