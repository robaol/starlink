      SUBROUTINE CCG1_SCD1D( NSIGMA, STACK, NPIX, NLINES, VARS,
     :                         MINPIX, COVEC, NMAT, RESULT, RESVAR,
     :                         WRK1, WRK2, NCON, POINT, USED, STATUS )
*+
*  Name:
*     CCG1_SCD1

*  Purpose:
*     Combines data lines using a sigma clipped mean.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL CCG1_SCD1( NSIGMA, STACK, NPIX, NLINES, VARS, MINPIX, COVEC,
*                     NMAT, RESULT, RESVAR, WRK1, WRK2, NCON, POINT,
*                     USED, STATUS )

*  Description:
*     This routine accepts an array consisting a series of (vectorised)
*     lines of data. The weighted mean and standard deviation of each
*     input column in STACK is then used to estimate the range of
*     values which represent the required sigma clipping. Values
*     outside of this range are then rejected and  the resulting output
*     mean values are returned in the array RESULT.The variances are
*     propagation through the combination processand returned in the
*     RESVAR array.


*  Arguments:
*     NSIGMA = REAL (Given)
*        The number of sigma at which to reject data values.
*     STACK( NPIX, NLINES ) = DOUBLE PRECISION (Given)
*        The array of lines which are to be combined into a single line.
*     NPIX = INTEGER (Given)
*        The number of pixels in a line of data.
*     NLINES = INTEGER (Given)
*        The number of lines of data in the stack.
*     VARS( NPIX, NLINES ) = DOUBLE PRECISION (Given)
*        The data variances.
*     MINPIX = INTEGER (Given)
*        The minimum number of pixels required to contribute to an
*        output pixel.
*     COVEC( NMAT, NLINES ) = DOUBLE PRECISION (Given)
*        The packed variance-covariance matrix of the order statistics
*        from a normal distribution of sizes up to NLINES, produced by
*        CCD1_ORVAR.
*     NMAT = INTEGER (Given)
*        Size of the first dimension of COVEC.
*     RESULT( NPIX ) = DOUBLE PRECISION (Returned)
*        The output line of data.
*     RESVAR( NPIX ) = DOUBLE PRECISION (Returned)
*        The output variances.
*     WRK1( NLINES ) = DOUBLE PRECISION (Given and Returned)
*        Workspace for calculations.
*     WRK2( NLINES ) = DOUBLE PRECISION (Given and Returned)
*        Workspace for calculations.
*     NCON( NLINES ) = DOUBLE PRECISION (Given and Returned)
*        The actual number of contributing pixels.
*     POINT( NLINES ) = INTEGER (Given and Returned)
*        Workspace to hold pointers to the original positions of the
*        data before extraction and conversion in to the WRK1 array.
*     USED( NLINES ) = LOGICAL (Given and Returned)
*        Workspace used to indicate which values have been used in
*        estimating a resultant value.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     PDRAPER: Peter Draper (STARLINK)
*     BRADC: Brad Cavanagh (JAC)
*     {enter_new_authors_here}

*  History:
*     21-MAY-1992 (PDRAPER):
*        Original version.
*     28-MAY-1992 (PDRAPER):
*        Now performs weighted sum of covariances.
*     11-OCT-2004 (BRADC):
*        No longer use NUM_CMN.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! PRIMDAT constants

*  Arguments Given:
      REAL NSIGMA
      INTEGER NPIX
      INTEGER NLINES
      INTEGER MINPIX
      INTEGER NMAT
      DOUBLE PRECISION STACK( NPIX, NLINES )
      DOUBLE PRECISION VARS( NPIX, NLINES )
      DOUBLE PRECISION COVEC( NMAT, NLINES )

*  Arguments Given and Returned:
      DOUBLE PRECISION NCON( NLINES )
      DOUBLE PRECISION WRK1( NLINES )
      DOUBLE PRECISION WRK2( NLINES )

*  Arguments Returned:
      DOUBLE PRECISION RESULT( NPIX )
      DOUBLE PRECISION RESVAR( NPIX )
      LOGICAL USED( NLINES )
      INTEGER POINT( NLINES )

*  Status:
      INTEGER STATUS             ! Global status

*  Global Variables:


*  External References:
      EXTERNAL NUM_WASOK
      LOGICAL NUM_WASOK          ! Was numeric operation ok?
      EXTERNAL NUM_TRAP
      INTEGER NUM_TRAP           ! Numerical error handler

*  Local Variables:
      DOUBLE PRECISION DVAL1     ! Dummy DBLE value
      DOUBLE PRECISION DVAL2     ! Dummy DBLE value
      DOUBLE PRECISION VAL       ! Weighted mean
      DOUBLE PRECISION VAR       ! Population variance before rejection
      DOUBLE PRECISION SUM1      ! Weight sums
      DOUBLE PRECISION SUM2      ! Weighted value sums
      DOUBLE PRECISION W1        ! Weight
      DOUBLE PRECISION W2        ! Weight
      INTEGER NGOOD              ! Number of good pixels
      INTEGER IGOOD              ! Number of unrejected pixels
      INTEGER LBND               ! Position of lowest value higher than
                                 ! rejection threshold
      INTEGER UBND               ! Position of highest value lower than
                                 ! rejection threshold
      INTEGER I                  ! Loop variable
      INTEGER J                  ! Loop variable
      INTEGER K                  ! Loop variable

*  Internal References:
      INCLUDE 'NUM_DEC_CVT'      ! NUM_ type conversion functions
      INCLUDE 'NUM_DEF_CVT'      ! Define functions...

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Set the numeric error and set error flag value.
      CALL NUM_HANDL( NUM_TRAP )

*  Loop over for all possible output pixels.
      DO 1 I = 1, NPIX
         NGOOD = 0
         CALL NUM_CLEARERR()
         SUM1 = 0.0D0
         SUM2 = 0.0D0

*  Loop over all possible contributing pixels.
         DO 2 J = 1, NLINES
            IF( STACK( I, J ) .NE. VAL__BADD .AND.
     :           VARS( I, J ) .NE. VAL__BADD ) THEN

*  Increment good value counter.
               NGOOD = NGOOD + 1

*  Update the pointers to the positions of the unextracted data.
               POINT( NGOOD ) = J

*  Convert input type to floating point value.
               DVAL1 = NUM_DTOD( STACK( I, J ) )

*  Change variance to weight.
               VAR = 1.0D0 / NUM_DTOD( VARS( I, J ) )

*  Increment sums.
               SUM2 = SUM2 + DVAL1 * VAR
               SUM1 = SUM1 + VAR

*  Transfer values to working buffers.
               WRK1( NGOOD ) = DVAL1
               WRK2( NGOOD ) = VAR

*  Set USED buffer in case no values are rejected.
               USED( NGOOD ) = .TRUE.

*  Finally trap numeric errors by rejecting all values.
               IF ( .NOT. NUM_WASOK() ) THEN

*  Decrement NGOOD, do not let it go below zero.
                  NGOOD = MAX( 0, NGOOD - 1 )
                  CALL NUM_CLEARERR()
               END IF
            END IF
 2       CONTINUE

*  Continue if more than one good value.
         IF ( NGOOD .GT. 0 ) THEN

*  Form the weighted mean and population standard deviation.
            VAL = SUM2 / SUM1
            VAR = 1.0D0 / SUM1

*  Sort data prior to rejection -- this is necessary as clip may be
*  non-central for (noisy) skew distributions, so the order statitics
*  summation will be incorrect if we procede assuming that the mean is
*  central and so correspondling are the covariances.
            CALL CCG1_IS3D( WRK1, WRK2, POINT, NGOOD, STATUS )

*  Set the clipping range.
            DVAL1 = VAL - DBLE( NSIGMA ) * SQRT( VAR )
            DVAL2 = VAL + DBLE( NSIGMA ) * SQRT( VAR )

*  Decide which orders of data are to be rejected. Pick out the least
*  bound greater than the lower bound and the highest bound less than
*  the upper bound.
            LBND = NGOOD
            UBND = 1
            DO 3 J = 1, NGOOD
               IF ( WRK1( J ) .GT. DVAL1 ) LBND = MIN( LBND, J )
               IF ( WRK1( J ) .LT. DVAL2 ) UBND = MAX( UBND, J )
 3          CONTINUE

*  Number of rejected values.
            IGOOD = UBND - LBND + 1

*  If any values have been rejected then form new mean.
            IF ( IGOOD .GT. 0 ) THEN
               IF ( NGOOD .NE. IGOOD ) THEN

*  New mean required.
                  SUM1 = 0.0D0
                  SUM2 = 0.0D0
                  DO 4 J = 1, NGOOD
                     IF ( J .GE. LBND .AND. J .LE. UBND ) THEN

*  Increment sums.
                        SUM2 = SUM2 + WRK1( J ) * WRK2( J )
                        SUM1 = SUM1 + WRK2( J )
                        USED( J ) = .TRUE.
                     ELSE
                        USED( J ) = .FALSE.
                     END IF
 4                CONTINUE

*  New mean.
                  VAL = SUM2 / SUM1

*  Sum variance-covariances for this population size using the weights.
                  SUM2 = 0.0D0
                  SUM1 = 0.0D0
                  DO 5 J = LBND, UBND
                     W1 = WRK2( J )
                     DO 6 K = J, UBND
                        IF( J .EQ. K ) THEN
                           W2 = W1 * WRK2( K )
                        ELSE
                           W2 = 2.0D0 * W1 * WRK2( K )
                        END IF
                        SUM1 = SUM1 + W2 *
     :                         COVEC( J + K * ( K - 1 ) / 2, NGOOD )
                        SUM2 = SUM2 + W2
 6                   CONTINUE
 5                CONTINUE

*  Variance modification factor.
                  SUM2 = SUM1 / SUM2

*  Correct the original population variance.
                  VAR = SUM2 * VAR * NGOOD
               END IF

*  Increment line used buffer.
               DO 7 J = 1, NGOOD
                  IF ( USED ( J ) ) THEN
                     NCON( POINT( J ) ) = NCON( POINT( J ) ) + 1.0D0
                  END IF
 7             CONTINUE

*  Trap occasions when all values are rejected.
            ELSE
               NGOOD = 0
            END IF
         END IF

*  If there are sufficient good pixels output the result.
         IF ( NGOOD .GE. MINPIX ) THEN
            RESULT( I ) = VAL
            RESVAR( I ) = VAR

*  Trap numeric errors.
            IF ( .NOT. NUM_WASOK() ) THEN
               RESULT( I ) = VAL__BADD
               RESVAR( I ) = VAL__BADD
            END IF
         ELSE

*  Not enough contributing pixels, set output invalid.
            RESULT( I ) = VAL__BADD
            RESVAR( I ) = VAL__BADD
         END IF
 1    CONTINUE

*  Remove the numerical error handler.
      CALL NUM_REVRT

      END
* $Id$
