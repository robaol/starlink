*+  TASK_DEC0D - decode a character string as a value
      SUBROUTINE TASK_DEC0D ( STRING, DVAL, STATUS )
 
*    Description :
*     Convert the given character string into a value of type
*     DOUBLE PRECISION and return it in DVAL.
*     A routine exists for each type C, D, L, I, R.
 
*    Invocation :
*     CALL TASK_DEC0D ( STRING, DVAL, STATUS )
 
*    Parameters :
*     STRING=CHARACTER*(*) (given)
*           the string to be decoded
*     DVAL=DOUBLE PRECISION (returned)
*           the returned value
*     STATUS=INTEGER
 
*    Method :
*     Use CHR conversion routine.
 
*    Deficiencies :
*     <description of any deficiencies>
 
*    Bugs :
*     <description of any "bugs" which have not been fixed>
 
*    Authors :
*     W.F.Lupton (AAOEPP::WFL)
*     A J Chpperifeld (RLVAD::AJC)
 
*    History :
*     29.04.1989:  original (AAOEPP::WFL)
*      4.10.1992:  use CHR for portability (RLVAD::AJC)
*      6.09.1993:  remove hagover from GENERIC system (RLVAD::AJC)
 
*    Type Definitions :
      IMPLICIT NONE
 
*    Global constants :
      INCLUDE 'SAE_PAR'
      INCLUDE 'TASK_ERR'
 
*    Import :
      CHARACTER*(*) STRING  ! the character string to be decoded
 
*    Export :
      DOUBLE PRECISION DVAL         ! the returned value
 
*    Status :
      INTEGER STATUS
 
*    Local variables :
 
*-
 
      IF ( STATUS .NE. SAI__OK ) RETURN
 
*   Use appropriate CHR routine
      CALL CHR_CTOD( STRING, DVAL, STATUS )
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL EMS_SETC( 'STR', STRING )
         CALL ERR_REP( 'TSK_DEC0L1',
     :   'TASK_DEC0D: Failed to convert ^STR to DOUBLE PRECISION',
     :    STATUS )
      ENDIF
 
      END
