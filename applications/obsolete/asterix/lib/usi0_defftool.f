*+  USI0_DEFFTOOL - Define the FTOOL parameters system
      SUBROUTINE USI0_DEFFTOOL( PARID, STATUS )
*    Description :
*     <description of what the subroutine does - for user info>
*    Method :
*     <description of how the subroutine works - for programmer info>
*    Deficiencies :
*     <description of any deficiencies>
*    Bugs :
*     <description of any "bugs" which have not been fixed>
*    Authors :
*
*     David J. Allan (JET-X, University of Birmingham)
*
*    History :
*
*     21 May 93 : Original (DJA)
*     24 Nov 94 : Added _DELET method (DJA)
*     25 Nov 94 : Added _EXIST method (DJA)
*
*    Type definitions :
*
      IMPLICIT NONE
*
*    Global constants :
*
      INCLUDE 'SAE_PAR'
      INCLUDE 'DAT_PAR'
      INCLUDE 'USI0_PAR'
      INCLUDE 'USI_CMN'
*
*    Export :
*
      INTEGER			PARID			! Parameter system id
*
*    Status :
*
      INTEGER 			STATUS
*
*    External references :
*
      EXTERNAL			USI_BLK
      EXTERNAL                  UCLGSI
      EXTERNAL                  UCLGSR
      EXTERNAL                  UCLGSD
      EXTERNAL                  UCLGST
      EXTERNAL                  UCLGSL
*-

*   Define the new system
      CALL USI0_DEFSYS( 'FTOOL', PARID, STATUS )

*   Define the routines
*    Scalar DEF routines
c      CALL USI0_DEFRTN( PARID, USI__F_DEF0L, PAR_DEF0L, STATUS )
c      CALL USI0_DEFRTN( PARID, USI__F_DEF0I, PAR_DEF0I, STATUS )
c      CALL USI0_DEFRTN( PARID, USI__F_DEF0R, PAR_DEF0R, STATUS )
c      CALL USI0_DEFRTN( PARID, USI__F_DEF0D, PAR_DEF0D, STATUS )
c      CALL USI0_DEFRTN( PARID, USI__F_DEF0C, PAR_DEF0C, STATUS )

*    Vector DEF routines
c      CALL USI0_DEFRTN( PARID, USI__F_DEF1L, PAR_DEF1L, STATUS )
c      CALL USI0_DEFRTN( PARID, USI__F_DEF1I, PAR_DEF1I, STATUS )
c      CALL USI0_DEFRTN( PARID, USI__F_DEF1R, PAR_DEF1R, STATUS )
c      CALL USI0_DEFRTN( PARID, USI__F_DEF1D, PAR_DEF1D, STATUS )
c      CALL USI0_DEFRTN( PARID, USI__F_DEF1C, PAR_DEF1C, STATUS )

*    Scalar GET routines
      CALL USI0_DEFRTN( PARID, USI__F_GET0L, UCLGSL, STATUS )
      CALL USI0_DEFRTN( PARID, USI__F_GET0I, UCLGSI, STATUS )
      CALL USI0_DEFRTN( PARID, USI__F_GET0R, UCLGSR, STATUS )
      CALL USI0_DEFRTN( PARID, USI__F_GET0D, UCLGSD, STATUS )
      CALL USI0_DEFRTN( PARID, USI__F_GET0C, UCLGST, STATUS )

*    Vector GET routines
c      CALL USI0_DEFRTN( PARID, USI__F_GET1L, PAR_GET1L, STATUS )
c      CALL USI0_DEFRTN( PARID, USI__F_GET1I, PAR_GET1I, STATUS )
c      CALL USI0_DEFRTN( PARID, USI__F_GET1R, PAR_GET1R, STATUS )
c      CALL USI0_DEFRTN( PARID, USI__F_GET1D, PAR_GET1D, STATUS )
c      CALL USI0_DEFRTN( PARID, USI__F_GET1C, PAR_GET1C, STATUS )

*    Scalar PUT routines
c      CALL USI0_DEFRTN( PARID, USI__F_PUT0L, PAR_PUT0L, STATUS )
c      CALL USI0_DEFRTN( PARID, USI__F_PUT0I, PAR_PUT0I, STATUS )
c      CALL USI0_DEFRTN( PARID, USI__F_PUT0R, PAR_PUT0R, STATUS )
c      CALL USI0_DEFRTN( PARID, USI__F_PUT0D, PAR_PUT0D, STATUS )
c      CALL USI0_DEFRTN( PARID, USI__F_PUT0C, PAR_PUT0C, STATUS )

*    Vector PUT routines
c      CALL USI0_DEFRTN( PARID, USI__F_PUT1L, PAR_PUT1L, STATUS )
c      CALL USI0_DEFRTN( PARID, USI__F_PUT1I, PAR_PUT1I, STATUS )
c      CALL USI0_DEFRTN( PARID, USI__F_PUT1R, PAR_PUT1R, STATUS )
c      CALL USI0_DEFRTN( PARID, USI__F_PUT1D, PAR_PUT1D, STATUS )
c      CALL USI0_DEFRTN( PARID, USI__F_PUT1C, PAR_PUT1C, STATUS )

*    Odds and sodds
c      CALL USI0_DEFRTN( PARID, USI__F_CANCL, PAR_CANCL, STATUS )
c      CALL USI0_DEFRTN( PARID, USI__F_PROMT, PAR_PROMT, STATUS )
c      CALL USI0_DEFRTN( PARID, USI__F_STATE, PAR_STATE, STATUS )
c      CALL USI0_DEFRTN( PARID, USI__F_DASSOC, DAT_ASSOC, STATUS )
c      CALL USI0_DEFRTN( PARID, USI__F_DCREAT, DAT_CREAT, STATUS )
c      CALL USI0_DEFRTN( PARID, USI__F_DELET, DAT_DELET, STATUS )
c      CALL USI0_DEFRTN( PARID, USI__F_DEXIST, DAT_EXIST, STATUS )

      END
