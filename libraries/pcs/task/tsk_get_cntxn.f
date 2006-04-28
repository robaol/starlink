      SUBROUTINE TASK_GET_CONTEXTNAME ( CONTEXTNAME, STATUS )
*+
*  Name:
*     TASK_GET_CONTEXTNAME

*  Purpose:
*     Get current action context name

*  Language:
*     Starlink Fortran 77

*  Type Of Module:
*     SUBROUTINE

*  Invocation:
*     CALL TASK_GET_CONTEXTNAME ( CONTEXTNAME, STATUS)

*  Description:
*     Gets current action context name. This simply involves copying the
*     context from COMMON and converting it to a character string.

*  Arguments:
*     CONTEXTNAME=CHARACTER*(*) (returned)
*           The action context ('OBEY' or 'CANCEL'), truncated if not large
*           enough. If context is invalid, blank is returned.
*     STATUS=INTEGER

*  Algorithm:
*     Copy and convert information from COMMON.

*  Authors:
*     W.F.Lupton (AAOEPP::WFL)
*     {enter_new_authors_here}

*  History:
*     29-APR-1989 (AAOEPP::WFL):
*        Original
*     01-MAR-1990: make DATA statements more obvious make more secure
*                  (AAOEPP::WFL)
*     23-APR-1991 (REVAD::BDK):
*        Rearrange INCLUDE files
*     04-OCT-1992 (RLVAD::AJC):
*        Add PAR_PAR for porting
*     08-OCT-1992 (RLVAD::AJC):
*        Add CONTROL context
*     24-AUG-1993 (RLVAD::AJC):
*        Use SUBPAR_SYS not PAR_PAR
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE
*  Global Constants:
      INCLUDE 'SAE_PAR'
      INCLUDE 'SUBPAR_SYS'
      INCLUDE 'ADAM_DEFNS'
      INCLUDE 'MESSYS_LEN'
      INCLUDE 'TASK_PAR'

*  Arguments Returned:
      CHARACTER*(*) CONTEXTNAME ! the action context name ('OBEY' or 'CANCEL')

*  Status:
      INTEGER STATUS

*  Global Variables:
      INCLUDE 'TASK_CMN'

*  Local Variables:
      CHARACTER*7 CONTEXTNAMES(0:6) ! ADAM context names

*    Local data :
      DATA CONTEXTNAMES(0) / ' ' /
      DATA CONTEXTNAMES(SET) / 'SET' /
      DATA CONTEXTNAMES(GET) / 'GET' /
      DATA CONTEXTNAMES(OBEY) / 'OBEY' /
      DATA CONTEXTNAMES(CANCEL) / 'CANCEL' /
      DATA CONTEXTNAMES(CONTROL) / 'CONTROL' /
      DATA CONTEXTNAMES(6) / ' ' /
*.
      IF ( STATUS .NE. SAI__OK ) RETURN
*
*    Simply copy the value from COMMON.
*
      CONTEXTNAME = CONTEXTNAMES(MAX(0,MIN(6,CURACTCONTEXT)))

      END
