      SUBROUTINE FTS1_FNDFS( FC, OBJ, STATUS )
*+
*  Name:
*     FTS1_FNDFS

*  Purpose:
*     Read the first FrameSet from the supplied FitsChan.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL FTS1_FNDFS( FC, OBJ, STATUS )

*  Description:
*     This routine reads Objects from the supplied FitsChan until a
*     FrameSet is obtained, and returns the FrameSet.

*  Arguments:
*     FC = INTEGER (Given)
*        An AST pointer to the FitsChan.
*     OBJ = INTEGER (Given)
*        The AST pointer to the FrameSet. 
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     -  The FitsChan is not rewound before reading. The first read starts at 
*     the current Card in the FitsChan.
*     -  No value is set for the FitsChan Encoding attribute.
*     -  OBJ is returned equal to AST__NULL if no FrameSet can be read
*     from the supplied FitsChan, or if an error occurs.

*  Authors:
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     11-NOV-1997 (DSB):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'AST_PAR'          ! AST_ public constants

*  Arguments Given:
      INTEGER FC

*  Arguments Returned:
      INTEGER OBJ

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      LOGICAL DONE               ! Leave the loop?
*.

*  Initialise.
      OBJ = AST__NULL

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Loop until a FrameSet is obtained, or no more Objects remain in the
*  FitsChan, or an error occurs.
      DONE = .FALSE.
      DO WHILE( .NOT. DONE .AND. STATUS .EQ. SAI__OK )

*  Read the next Object. Annul any errors generated by AST_READ.
         CALL ERR_BEGIN( STATUS )
         OBJ = AST_READ( FC, STATUS )
         IF( STATUS .NE. SAI__OK ) CALL ERR_ANNUL( STATUS )
         CALL ERR_END( STATUS )

*  If an Object was read, and if the Object is a FrameSet, break out of
*  the loop. Otherwise annul the Object.
         IF( OBJ .NE. AST__NULL ) THEN
            IF( AST_ISAFRAMESET( OBJ, STATUS ) ) THEN
               DONE = .TRUE.
            ELSE
               CALL AST_ANNUL( OBJ, STATUS )
            END IF

*  If no more Objects were available, leave the loop.
         ELSE
            DONE = .TRUE.
         END IF

      END DO

*  Annul the Object if an error has occurred.
      IF( STATUS .NE. SAI__OK ) CALL AST_ANNUL( OBJ, STATUS )

      END
