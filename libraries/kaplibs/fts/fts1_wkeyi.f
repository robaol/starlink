      SUBROUTINE FTS1_WKEYI( NAME, VALUE, CMTBGN, COMNT, HEADER,
     :                         STATUS )
*+
*  Name:
*     FTS1_WKEYx

*  Purpose:
*     Writes a FITS-header card for a value of type INTEGER.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL FTS1_WKEYx( NAME, CMTBGN, VALUE, COMNT, HEADER, STATUS )

*  Description:
*     This routine writes a FITS-header card using the supplied
*     keyword, value, comment, and comment delimiter.  The value has
*     data type INTEGER.  The name may be compound to permit writing
*     of hierarchical keywords.

*  Arguments:
*     NAME = CHARACTER *( * ) (Given)
*        The name of the keyword to be written.  This may be a compound
*        name to handle hierarchical keywords, and it has the form
*        keyword1.keyword2.keyword3 etc.  The maximum number of
*        keywords per FITS card is 20.  The value is converted to
*        uppercase and blanks are removed before being used.  Each
*        keyword must be no longer than 8 characters.  The total length
*        must not exceed 48 characters.  This is to allow for the
*        value, and indentation into a blank-keyword card (as
*        hierarchical keywords are not standard and so cannot be part
*        of the standard keyword name).
*     VALUE = INTEGER (Given)
*        The value of the keyword.
*     CMTBGN = CHARACTER * ( 1 ) (Given)
*        The character which indicates the beginning of the comment
*        string of to be appended to the keyword.  Normally it is '/'.
*        when it is blank, no comment will be appended to the keyword.
*     COMNT = CHARACTER * ( * ) (Returned)
*        The comment string of the keyword.  It may be truncated at the
*        end to put into the space left after writing keyword value. 
*     HEADER = CHARACTER * ( 80 ) (Returned)
*        The created FITS-header card.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     - There is a routine for each of the data types logical, integer,
*     real and double precision: replace "x" in the routine name by L,
*     I, R or D as appropriate.
*     - The comments are written from column 32 or higher if the value
*     demands more than the customary 20 characters for the value.  A
*     comment may be omitted if the value is so long to leave no room.

*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1996 November 13 (MJC):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants

*  Arguments Given:
      CHARACTER * ( * ) NAME
      INTEGER VALUE
      CHARACTER * ( 1 ) CMTBGN
      CHARACTER * ( * ) COMNT

*  Arguments Returned:
      CHARACTER * ( 80 ) HEADER

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      INTEGER CHR_LEN            ! The used length of a string

*  Local Constants:
      INTEGER COMCOL             ! Minimum column position for the start
                                 ! of a FITS comment
      PARAMETER ( COMCOL = 32 )

      INTEGER COMLN              ! Maximum number of characters in a
                                 ! FITS header card comment
      PARAMETER ( COMLN = 69 )

      INTEGER CMPEQC             ! Minimum column position for the
                                 ! equals sign in a compound keyword
                                 ! of a FITS comment
      PARAMETER ( CMPEQC = 22 )

      INTEGER HKEYLN             ! Maximum number of characters in a
                                 ! FITS header card hierarchical keyword
      PARAMETER ( HKEYLN = 48 )

      INTEGER KEYLN              ! Maximum number of characters in a
                                 ! FITS header card keyword or
                                 ! hierarchical component thereof
      PARAMETER ( KEYLN = 8 )

      INTEGER VALLN              ! Maximum number of characters in a
                                 ! FITS header card value
      PARAMETER ( VALLN = 70 )

*  Local Variables:
      INTEGER CARDLN             ! Used length of a card image
      CHARACTER * ( VALLN ) CHRVAL  ! The value in characters
      INTEGER COMPOS             ! Position to start the comment and
                                 ! its delimiter
      LOGICAL COMPND             ! Compound-keyword flag
      CHARACTER * ( KEYLN ) CRDKEY ! Keyword of a card image
      INTEGER EQUALS             ! The position of equal sign
      INTEGER KEYLEN             ! Length of specified keyword
      CHARACTER * ( HKEYLN ) KEYWRD  ! Specified keyword
      CHARACTER * ( VALLN ) VALSTR ! String expression of keyword value
      INTEGER VALN               ! Length of the keyword value

*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Initialise the header.
      HEADER = ' '

*  Remove blanks from the keyword to be searched.  Change the keyword to
*  uppercase and get its used length.
      KEYWRD = NAME
      CALL CHR_RMBLK( KEYWRD )
      CALL CHR_UCASE( KEYWRD )
      KEYLEN = CHR_LEN( KEYWRD )

*  To see whether it is a compound name.
      COMPND = INDEX( KEYWRD, '.' ) .NE. 0

*  Specify the column for the equals sign.  In compound names, allow
*  for the blank keyword, then a space followed by a keyword then a
*  space.  Also replace the fullstops with spaces.  Bad status is
*  returned when the lengths of the replacement strings is not equal to
*  the substituted strings.  Here they are fixed, so STATUS need not be
*  checked.  Also specify the column one before where the keyword will
*  be written.
      IF ( COMPND ) THEN
         CARDLN = KEYLN + 1
         EQUALS = MAX( CMPEQC, KEYLEN + 1 + CARDLN )
         CALL CHR_TRCHR( '.', ' ', KEYWRD, STATUS )
      ELSE
         CARDLN = 0
         EQUALS = KEYLN + 1
      END IF

*  Start writing the card with the keyword and equals sign.
      CALL CHR_APPND( KEYWRD, HEADER, CARDLN )
      CARDLN = EQUALS - 1
      CALL CHR_APPND( '= ', HEADER, CARDLN )

*  Format the value string.
      CALL CHR_ITOC( VALUE, VALSTR, VALN )
         
*  See if there is any error during formation.
      IF ( VALSTR( : VALN ) .EQ. '*' ) THEN
         STATUS = SAI__ERROR
         CALL MSG_SETI( 'V', VALUE )
         CALL MSG_SETC( 'TYPE', 'INTEGER' )
         CALL ERR_REP( 'FTS1_WKEYI_TYPCNV',
     :     'Unable to convert the given value (^V) to the ^TYPE data '/
     :     /' type.', STATUS )
         GOTO 999

*  Deal with a logical which must be abbreviated to T or F, by limiting
*  it to its initial character.
      ELSE IF ( VALSTR( : VALN ) .EQ. 'TRUE' .OR.
     :          VALSTR( : VALN ) .EQ. 'FALSE' ) THEN
         VALN = 1

      END IF

*  Determine the column where the comment can begin.  If the length is
*  less the minimum, this leaves the card padded with blanks to the
*  minimum length.  The comment cannot begin before the minimum length
*  of a non-character value (including the cumpulsory space after the
*  equals sign), and so allowing for the trailing space, the comment
*  must not appear until two columns after this.
      COMPOS = MAX( COMCOL, EQUALS + VALN + 3 )

*  Insert the value, right justified.
      HEADER( COMPOS-1-VALN:COMPOS-2 ) = VALSTR( :VALN )

*  Only store a comment (new or old) if there is room for part of it.
      IF ( COMPOS .LT. 79 ) THEN

*  Initialise the character position.  The comment will be appended
*  from column COMPOS.
         CARDLN = COMPOS - 1

*  Append the comment string to the card, or as much as can fit on to
*  the card.  Notice that leading blanks are not removed from the
*  comment in case the user is attempting some clever alignment.  Since
*  a FITS comment may contain any ASCII character, it has not been
*  cleaned.
         CALL CHR_APPND( CMTBGN, HEADER, CARDLN )
         CARDLN = CARDLN + 1
         CALL CHR_APPND( COMNT, HEADER, CARDLN )
      
      END IF

  999 CONTINUE

      END
