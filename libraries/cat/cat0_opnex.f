      SUBROUTINE CAT0_OPNEX (BCKTYP, CATNAM, CATFIL, EXTRA,
     :  MODE, CI, STATUS)
      IMPLICIT NONE
      INTEGER BCKTYP, CI, STATUS
      CHARACTER*(*) CATNAM, CATFIL, EXTRA, MODE
      INCLUDE 'CAT_PAR' 
      INCLUDE 'CAT1_PAR' 

      IF (STATUS .NE. CAT__OK) RETURN

      IF (BCKTYP .EQ. CAT1__BKFIT) THEN
         CALL CAT3_OPNEX (CATNAM, CATFIL, EXTRA, MODE, CI, 
     :    STATUS)
      ELSE IF (BCKTYP .EQ. CAT1__BKSTL) THEN
         CALL CAT5_OPNEX (CATNAM, CATFIL, EXTRA, MODE, CI, 
     :    STATUS)
      ELSE IF (BCKTYP .EQ. CAT1__BKTST) THEN
         CALL CAT6_OPNEX (CATNAM, CATFIL, EXTRA, MODE, CI, 
     :    STATUS)
      END IF

      END
