      SUBROUTINE CAT0_RSTXT (BCKTYP, CI, STATUS)
      IMPLICIT NONE
      INTEGER BCKTYP, CI, STATUS
      INCLUDE 'CAT_PAR' 
      INCLUDE 'CAT1_PAR' 

      IF (STATUS .NE. CAT__OK) RETURN

      IF (BCKTYP .EQ. CAT1__BKFIT) THEN
         CALL CAT3_RSTXT (CI, STATUS)
      ELSE IF (BCKTYP .EQ. CAT1__BKSTL) THEN
         CALL CAT5_RSTXT (CI, STATUS)
      ELSE IF (BCKTYP .EQ. CAT1__BKTST) THEN
         CALL CAT6_RSTXT (CI, STATUS)
      END IF

      END
