C# IL>=a, OL>=0
      SUBROUTINE GKPWGS(IDNR,ISTATE,RSTATE)


*---------------------------------------------------------------------
*
*  RUTHERFORD / ICL GKS SYSTEM
*
*  Type of routine:    Workstation utility
*  Author:             MGC
*
      INCLUDE '../include/check.inc'
*
*  PURPOSE OF THE ROUTINE
*  ----------------------
*     Get pick device state.
*
*  MAINTENANCE LOG
*  ---------------
*     01/08/85  MGC   Original version stabilised
*
*  ARGUMENTS
*  ---------
*     INP IDNR           - Pick device number
*     OUT ISTATE(KPCNWI) - Device state integers
*     OUT RSTATE(KPCNWR) - Device state reals
*
      INTEGER IDNR
      INTEGER ISTATE(*)
      REAL    RSTATE(*)
*
*  COMMON BLOCK USAGE
*  ------------------
*
      INCLUDE '../include/gkinp.par'
      INCLUDE '../include/gks.par'
      INCLUDE '../include/gkwpc.par'
      INCLUDE '../include/gkerr.cmn'
*
*  LOCALS
*  ------
*     IDEV    Device entry integers
*     RDEV    Device entry real
*
      INTEGER IDEV(KPCNI)
      REAL    RDEV(KPCNR)
*
*  ERRORS
*  ------
*
*---------------------------------------------------------------------


*     get pick device details
      CALL GKRQIP(GPICK,IDNR,KPCNI,KPCNR,IDEV,RDEV)
      IF(KERROR.EQ.0) THEN
        CALL GKHPGI(IDEV(KPCIWI),0,KPCNWI,ISTATE)
        CALL GKHPGR(IDEV(KPCIWR),0,KPCNWR,RSTATE)
      ENDIF

      END
