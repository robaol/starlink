*+  TASK_VAL0R - encode a value as a character string
      SUBROUTINE TASK_VAL0R ( RVAL, STRING, STATUS )
*    Description :
*     Convert the given value of type REAL into a character
*     string and return it in STRING.
*     A routine exists for each type C, D, L, I, R.
*    Invocation :
*     CALL TASK_VAL0R ( RVAL, STRING, STATUS )
*    Parameters :
*     RVAL=REAL (given)
*           the value to be encoded
*     STRING=CHARACTER*(*) (returned)
*           the returned character string
*     STATUS=INTEGER
*    Method :
*     Call TASK_ENC0R
*    Deficiencies :
*     <description of any deficiencies>
*    Bugs :
*     <description of any "bugs" which have not been fixed>
*    Authors :
*     B.D.Kelly (REVAD::BDK)
*    History :
*     06.11.1987:  original (REVAD::BDK)
*     29.04.1989:  make it generic (same as TASK_ENC0R) (AAOEPP::WFL)
*    endhistory
*    Type Definitions :
      IMPLICIT NONE
*    Global constants :
      INCLUDE 'SAE_PAR'
 
*    Import :
      REAL RVAL         ! the value to be encoded
 
*    Export :
      CHARACTER*(*) STRING  ! the returned character string
 
*    Status :
      INTEGER STATUS
*-
 
      IF ( STATUS .NE. SAI__OK ) RETURN
 
      CALL TASK_ENC0R ( RVAL, STRING, STATUS )
 
      END
 
!*+  TASK_VAL0 - encode a value as a character string
!      SUBROUTINE TASK_VAL0
!*    Description :
!*     Dummy routine to allow MMS to maintain the object library properly
!
!      END
