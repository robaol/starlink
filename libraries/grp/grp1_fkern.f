      SUBROUTINE GRP1_FKERN( SLOT, FIRST, TEXT, NEXT, P1, P2, K1, K2, 
     :                       S1, S2, T1, T2, F, L, STATUS )
*+
*  Name:
*     GRP1_FKERN

*  Purpose:
*     Find the inner-most kernel within an element expression.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL GRP1_FKERN( SLOT, FIRST, TEXT, NEXT, P1, P2, K1, K2, S1, S2,
*                      T1, T2, F, L, STATUS )

*  Description:
*     Kernel expressions can be nested, one within another. This
*     subroutine, parses each level of kernel nesting until the
*     inner-most kernel is found (i.e. a kernel which either contains no
*     further kernels within it), or until a kernel is found which
*     contains a list of elements separated by the DELIMITER control
*     character. The start and end of any prefix, suffix or substitution
*     strings which apply to to the found kernel are also returned.
*
*     If the supplied text contains more than one element at zero
*     levels of kernel nesting, then the location of the DELIMITER
*     character which marks the end of the first element is returned in
*     NEXT.
*
*     When the returned kernel is expanded and any editing is applied,
*     it will result in one or more literal names. The bounds of the
*     section of the supplied text string which should be replaced by
*     these names are returned in argument F and L.
*
*     Any comment included in the supplied group expression are removed
*     before it is used.

*  Arguments:
*     SLOT = INTEGER (Given)
*        The group which defined the control characters used to parse
*        the group expression.
*     FIRST = INTEGER (Given)
*        The index (within TEXT) of the first character to be
*        considered.
*     TEXT = CHARACTER * ( * ) (Given and Returned)
*        The text of the element or group expression. Any comment 
*        contained in the supplied value is removed from the returned 
*        value.
*     NEXT = INTEGER (Returned)
*        The index (within TEXT) of the element DELIMITER character
*        which marks the end of the first element within the specified
*        section of the supplied text. Delimiter characters which occur
*        within kernels are ignored. NEXT is returned equal to zero if
*        no such delimiter is found.
*     P1 = INTEGER (Returned)
*        The index of the first character in the prefix which is to be
*        applied to the returned kernel.
*     P2 = INTEGER (Returned)
*        The index of the last character in the prefix. Returned less
*        than P1 if there is no prefix or if the prefix is blank.
*     K1 = INTEGER (Returned)
*        The index of the first character in the kernel.
*     K2 = INTEGER (Returned)
*        The index of the last character in the kernel. Retuned less
*        than K1 if the kernel is blank.
*     S1 = INTEGER (Returned)
*        The index of the first character in the suffix to be applied to
*        the returned kernel.
*     S2 = INTEGER (Returned)
*        The index of the last character in the suffix. Returned less
*        than S1 if there is no suffix or if the suffix is blank.
*     T1 = INTEGER (Returned)
*        The index of the first character in the substitution string to
*        be applied to the returned kernel (i.e. the index of the first
*        SEPARATOR character).
*     T2 = INTEGER (Returned)
*        The index of the last character in the substitution string
*        (i.e. the index of the third SEPARATOR character).  Returned
*        less than T1 if there is no substitition string.
*     F = INTEGER (Returned)
*        The starting index of the section of the supplied text to be
*        over-writen by a name generated by expanding the returned
*        kernel.
*     L = INTEGER (Returned)
*        The ending index of the section of the supplied text to be
*        over-writen by a name generated by expanding the returned
*        kernel.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Authors:
*     DSB: David Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     26-JAN-1994 (DSB):
*        Original version.
*     27-AUG-1999 (DSB):
*        Added control character escape facility.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'GRP_CONST'        ! Private GRP constants

*  Arguments Given:
      INTEGER SLOT
      INTEGER FIRST

*  Arguments Given and Returned:
      CHARACTER TEXT*(*)

*  Arguments Returned:
      INTEGER NEXT
      INTEGER P1
      INTEGER P2
      INTEGER K1
      INTEGER K2
      INTEGER S1
      INTEGER S2
      INTEGER T1
      INTEGER T2
      INTEGER F
      INTEGER L

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      INTEGER CHR_LEN            ! Used length of a string
      INTEGER GRP1_INDEX         ! Finds un-escaped control characters
      LOGICAL GRP1_CHKCC         ! See if a character is a control character

*  Local Variables:
      INTEGER COM                ! Index of the comment character
      CHARACTER COMC*1           ! Groups current omment character.
      LOGICAL COMOK              ! .TRUE. if COMC is not NULL.
      CHARACTER ESCC*1           ! The escape character
      LOGICAL ESCOK              ! Is the escape character defined?
      INTEGER FL                 ! Value of F on previous pass
      LOGICAL FPASS              ! Is this the first pass thru the loop?
      INTEGER K1L                ! Value of K1 on previous pass
      INTEGER K2L                ! Value of K2 on previous pass
      INTEGER LL                 ! Value of L on previous pass
      LOGICAL MORE               ! Is loop to be executed again?
      INTEGER P1L                ! Value of P1 on previous pass
      INTEGER P2L                ! Value of P2 on previous pass
      INTEGER S1L                ! Value of S1 on previous pass
      INTEGER S2L                ! Value of S2 on previous pass
      INTEGER T1L                ! Value of T1 on previous pass
      INTEGER T2L                ! Value of T2 on previous pass

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise the returned pointers.
      P1 = 1
      P2 = 0
      K1 = FIRST
      K2 = FIRST - 1 
      S1 = 1
      S2 = 0
      T1 = 1
      T2 = 0

*  Get the group's current escape character.
      CALL GRP1_CONC( SLOT, GRP__PESCC, ESCC, ESCOK, STATUS )

*  Get the group's current comment character.
      CALL GRP1_CONC( SLOT, GRP__PCOMC, COMC, COMOK, STATUS )

*  If a comment character is defined search for the first occurrence 
*  of the comment character in the supplied group expression.
      IF( COMOK ) THEN
         COM = GRP1_INDEX( TEXT, COMC, ESCC, ESCOK )

*  If a comment was found, remove it.
         IF( COM .GT. 0 ) TEXT( COM : ) = ' '

      END IF

*  Set up the bounds of the part of the element or group expression to
*  be used. 
      F = FIRST
      L = CHR_LEN( TEXT )

*  If the supplied starting position is beyond the end of the string,
*  return a blank kernel and indicate that no more elements remain in
*  the string.
      IF( F .GT. L ) THEN
         NEXT = 0

*  Otherwise, loop until a kernel is found which is a single element
*  without any editing, or until a kernel is found which is a list of
*  elements, or until a kernel is found which is blank, or an error
*  occurs.
      ELSE

*  Set up a flag indicating that this is the first pass through the
*  loop.
         FPASS = .TRUE.

*  Initialise the "previous" values of K1, K2, etc.
         K1L = 1
         K2L = 1
         P1L = 1
         P2L = 1
         S1L = 1
         S2L = 1
         T1L = 1
         T2L = 1

*  Enter the loop.
         MORE = .TRUE.
         DO WHILE( MORE )

*  Identify the prefix, kernel, suffix and substitution strings within
*  the current section of the supplied string (i.e. the section bounded
*  by indices F and L).
            CALL GRP1_PAREL( SLOT, TEXT( : L ), F, P1, P2, K1, K2, S1,
     :                       S2, T1, T2, NEXT, STATUS )
            IF( STATUS .EQ. SAI__OK ) THEN

*  If the kernel identified contains more than one element, then we
*  have performed one too many passes through this loop. Return the
*  previous passes values. The exception to this is if this is the first
*  pass (i.e. if the supplied group expression contains two or more
*  elements at the outer-most level). In this case, the current passes
*  values are returned.
               IF( NEXT .GT. 0 ) THEN
                  MORE = .FALSE.

                  IF( .NOT. FPASS ) THEN
                     F = FL
                     L = LL
                     K1 = K1L
                     K2 = K2L      
                     P1 = P1L
                     P2 = P2L      
                     S1 = S1L
                     S2 = S2L      
                     T1 = T1L
                     T2 = T2L      
                     NEXT = 0
                  END IF

*  If the kernel identified is blank, then we have certainly found the
*  inner-most kernel, and there is no need to check that there are any
*  further nested kernels within it. So return the current values of F
*  and L.
               ELSE IF( K2 .LT. K1 ) THEN
                  MORE = .FALSE.

               ELSE IF( TEXT( K1 : K2 ) .EQ. ' ' ) THEN
                  MORE = .FALSE.

*  If the kernel is not blank, check to see if it is the same as the
*  kernel identified on the previous pass. If it is then we have found
*  the inner-most kernel, so return the values of F and L from the
*  previous pass. If this is the first pass through the loop, then we
*  must always make at least one more pass to ensure that the kernel
*  just found does not contain any deeper nested kernels within it.
               ELSE IF( TEXT( K1 : K2 ) .EQ. TEXT( K1L : K2L ) .AND.
     :                  ( .NOT. FPASS ) ) THEN
                  MORE = .FALSE.
                  F = FL
                  L = LL
                  P1 = P1L
                  P2 = P2L      
                  S1 = S1L
                  S2 = S2L      
                  T1 = T1L
                  T2 = T2L      

*  If the kernel is different to the kernel on the previous pass, then
*  we cannot be sure that the inner-most kernel has been found. Go
*  round again to see if any further nested kernels exist within the
*  kernel just found. 
               ELSE
                  K1L = K1
                  K2L = K2
                  P1L = P1
                  P2L = P2
                  S1L = S1
                  S2L = S2
                  T1L = T1
                  T2L = T2
                  FL = F
                  LL = L
                  F = K1
                  L = K2
               END IF

*  Leave the loop if an error has occurred.
            ELSE
               MORE = .FALSE.
            END IF
   
*  Indicate that this is the end of the first pass through the loop.
            FPASS = .FALSE.

         END DO

      END IF

      END
