      SUBROUTINE POL1_GTWCS( INDF, TR, IWCS, STATUS )
*+
*  Name:
*     POL1_GTWCS

*  Purpose:
*     Get a FrameSet describing the WCS information to be stored with the
*     output 2D images created by polvec.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*      CALL POL1_GTWCS( INDF, TR, IWCS, STATUS )

*  Description:
*     This routine gets the FrameSet from the WCS component of the
*     supplied NDF. The Base Frame of this FrameSet (describing GRID
*     coordinates in the supplied NDF) is 3 dimensional. A new 2D
*     Frame is added to the FrameSet which represents GRID coordinates 
*     in the binned 2D images created by polvec. This 2D Frame is
*     connected to the original 3D GRID Frame by scaling and shifting
*     axes 1 and 2 according to the values supplied in TR. Since all 
*     the planes in the input cube are presumed to be aligned, axis 3
*     is ignored. A new 2D PIXEL Frame is added to the FrameSet assuming
*     pixel indices equals grid indices. Finally the original GRID and 
*     PIXEL Frames are removed.

*  Arguments:
*     INDF = INTEGER (Given)
*        The 3-D input NDF.
*     TR( 4 ) = DOUBLE PRECISION (Given)
*        The coefficients of the linear mapping produced by the binning:
*           X' = TR1 + TR2*X
*           Y' = TR3 + TR4*Y
*           Z' = Z
*        where (X,Y,Z) are GRID coordinates in the input cube, and
*        (X',Y',Z') are GRID coordinates in the binned cube.
*     IWCS = INTEGER (Returned)
*        An AST identifier for the FrameSet to be stored with the output
*        2-D images created by polvec.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 1998 Central Laboratory of the Research Councils
 
*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     13-JAN-1998 (DSB):
*        Original version.
*     2-JUL-1998 (DSB):
*        Changed the corners of the box used to define the WinMap so
*        that it never has zero area. Supplied "1.0D0" instead of "1.0"
*        as constant value to AST_PERMMAP.
*     5-AUG-1998 (DSB):
*        Re-instate original Current Frame after adding new PIXEL Frame.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'AST_PAR'          ! AST__ constants

*  Arguments Given:
      INTEGER INDF
      DOUBLE PRECISION TR( 4 )

*  Arguments Returned:
      INTEGER IWCS

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      DOUBLE PRECISION INA( 2 )  ! Old GRID coords at point A
      DOUBLE PRECISION INB( 2 )  ! Old GRID coords at point B
      DOUBLE PRECISION OUTA( 2 ) ! New GRID coords at point A
      DOUBLE PRECISION OUTB( 2 ) ! New GRID coords at point B
      INTEGER CMP                ! Pointer to a CmpMap
      INTEGER FRM                ! Pointer to the new 2D Frame
      INTEGER IBASE              ! Index of original Base Frame
      INTEGER ICURR              ! Index of original Current Frame
      INTEGER INEW               ! Index of new Frame
      INTEGER IPIX               ! Index of old PIXEL Frame
      INTEGER INPERM( 3 )        ! O/p axis mapping to each i/p axis
      INTEGER OUTPERM( 2 )       ! I/p axis mapping to each o/p axis
      INTEGER PERM               ! Pointer to a PermMap
      INTEGER TEMP               ! Pointer to FrameSet
      INTEGER WIN                ! Pointer to a WinMap
*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Begin an AST context.
      CALL AST_BEGIN( STATUS )

*  Get the WCS information from the supplied 3D NDF.
      CALL NDF_GTWCS( INDF, IWCS, STATUS )

*  Create a PermMap which will create a 2D Frame from the first 2
*  axes of the 3D GRID Frame included in the above FrameSet. The
*  constant value 1.0 is assigned to axis 3 when doing an inverse
*  transformation (i.e. from 2D Frame to 3D Frame).
      INPERM( 1 ) = 1
      INPERM( 2 ) = 2
      INPERM( 3 ) = -1
      OUTPERM( 1 ) = 1
      OUTPERM( 2 ) = 2
      
      PERM = AST_PERMMAP( 3, INPERM, 2, OUTPERM, 1.0D0, ' ', STATUS )

*  Now create a WinMap which scales and shifts each axis in the 2D Frame
*  according to the values supplied in TR. 
      INA( 1 ) = 0.0D0
      INA( 2 ) = 0.0D0
      INB( 1 ) = 1.0D0
      INB( 2 ) = 1.0D0

      OUTA( 1 ) = TR( 1 )
      OUTA( 2 ) = TR( 3 )
      OUTB( 1 ) = TR( 1 ) + TR( 2 )
      OUTB( 2 ) = TR( 3 ) + TR( 4 )

      WIN = AST_WINMAP( 2, INA, INB, OUTA, OUTB, ' ', STATUS ) 

*  Concatenate and simplify these two mappings.
      CMP = AST_SIMPLIFY( AST_CMPMAP( PERM, WIN, .TRUE., ' ', STATUS ),
     :                    STATUS )

*  Create the new 2D GRID Frame.
      FRM = AST_FRAME( 2, 'DOMAIN=GRID', STATUS ) 
      CALL AST_SETC( FRM, 'Title', 'Data grid indices', STATUS )
      CALL AST_SETC( FRM, 'Label(1)', 'Data grid index 1', STATUS )
      CALL AST_SETC( FRM, 'Label(2)', 'Data grid index 2', STATUS )
      CALL AST_SETC( FRM, 'Symbol(1)', 'g1', STATUS )
      CALL AST_SETC( FRM, 'Symbol(2)', 'g2', STATUS )
      CALL AST_SETC( FRM, 'Unit(1)', 'pixel', STATUS )
      CALL AST_SETC( FRM, 'Unit(2)', 'pixel', STATUS )

*  Save the indices of the Base (i.e. GRID) and Current Frames.
      IBASE = AST_GETI( IWCS, 'BASE', STATUS )
      ICURR = AST_GETI( IWCS, 'CURRENT', STATUS )

*  Add the new 2D GRID Frame into the FrameSet, connecting it to
*  the base (i.e. GRID) Frame using the mapping created above.
      CALL AST_ADDFRAME( IWCS, AST__BASE, CMP, FRM, STATUS ) 

*  The above call will have changed the Current Frame to be the new Frame. 
*  Get its index.
      INEW = AST_GETI( IWCS, 'CURRENT', STATUS )

*  Re-instate the original Current Frame, and make the new Frame the base
*  Frame.
      CALL AST_SETI( IWCS, 'CURRENT', ICURR, STATUS )      
      CALL AST_SETI( IWCS, 'BASE', INEW, STATUS )      

*  Find the 3D PIXEL Frame within the WCS FrameSet. It becomes the
*  Current Frame.
      TEMP = AST_FINDFRAME( IWCS, AST_FRAME( 3, ' ', STATUS ), 'PIXEL',
     :                      STATUS )

*  Report an error if no PIXEL Frame was found. Otherwise, annul the
*  returned FrameSet.
      IF( TEMP .EQ. AST__NULL .AND. STATUS .EQ. SAI__OK ) THEN
         STATUS = SAI__ERROR
         CALL NDF_MSG( 'NDF', INDF )
         CALL ERR_REP( 'POL1_GTWCS_1', 'No PIXEL Frame found in WCS '//
     :                'component of ^NDF (possible programming error).',
     :                STATUS )
      ELSE 
         CALL AST_ANNUL( TEMP, STATUS )
      END IF

*  Get the index of the 3D PIXEL Frame, and re-instate the original
*  Current Frame.
      IPIX = AST_GETI( IWCS, 'CURRENT', STATUS )
      CALL AST_SETI( IWCS, 'CURRENT', ICURR, STATUS )      

*  Create a new 2D PIXEL Frame.
      FRM = AST_FRAME( 2, 'DOMAIN=PIXEL', STATUS ) 
      CALL AST_SETC( FRM, 'Title', 'Pixel coordinates', STATUS )
      CALL AST_SETC( FRM, 'Label(1)', 'Pixel coordinate 1', STATUS )
      CALL AST_SETC( FRM, 'Label(2)', 'Pixel coordinate 2', STATUS )
      CALL AST_SETC( FRM, 'Symbol(1)', 'p1', STATUS )
      CALL AST_SETC( FRM, 'Symbol(2)', 'p2', STATUS )
      CALL AST_SETC( FRM, 'Unit(1)', 'pixel', STATUS )
      CALL AST_SETC( FRM, 'Unit(2)', 'pixel', STATUS )

*  Create a WinMap which shifts each axis in the 2D GRID Frame
*  onto the 2D PIXEL Frame.
      INA( 1 ) = 0.5D0
      INA( 2 ) = 0.5D0
      INB( 1 ) = 1.5D0
      INB( 2 ) = 1.5D0

      OUTA( 1 ) = 0.0D0
      OUTA( 2 ) = 0.0D0
      OUTB( 1 ) = 1.0D0
      OUTB( 2 ) = 1.0D0

      WIN = AST_WINMAP( 2, INA, INB, OUTA, OUTB, ' ', STATUS ) 

*  Add the new 2D PIXEL Frame into the FrameSet, connecting it to
*  the base (i.e. GRID) Frame using the mapping created above.
      CALL AST_ADDFRAME( IWCS, AST__BASE, WIN, FRM, STATUS ) 

*  If the original Current Frame was the 3D Grid Frame, make the 2D GRID
*  Frame the Current Frame.
      IF( ICURR .EQ. IBASE ) THEN
         CALL AST_SETI( IWCS, 'CURRENT', INEW, STATUS )

*  If the original Current Frame was the 3D PIXEL Frame, leave the 2D PIXEL
*  as the Current Frame. Otherwise, reinstate the original Current Frame.
      ELSE IF( ICURR .NE. IPIX ) THEN
         CALL AST_SETI( IWCS, 'CURRENT', ICURR, STATUS )
      END IF

*  Remove the original 3D GRID and PIXEL Frames, highest index first.
      CALL AST_REMOVEFRAME( IWCS, MAX( IBASE, IPIX ), STATUS )
      CALL AST_REMOVEFRAME( IWCS, MIN( IBASE, IPIX ), STATUS )

*  Export the identifier for the returned FrameSets to the next higher
*  context level. This means it will not be annulled by the following
*  call to AST_END.
      CALL AST_EXPORT( IWCS, STATUS )

*  End the AST context.
      CALL AST_END( STATUS )

      END
