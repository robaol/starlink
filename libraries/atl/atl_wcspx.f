      SUBROUTINE ATL_WCSPX( IMAP, DIM, OBSLON, OBSLAT, IWCS, STATUS )
*+
*  Name:
*     ATL_WCSPX

*  Purpose:
*     Create a WCS FrameSet from a SPECX file.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL ATL_WCSPX( IMAP, DIM, OBSLON, OBSLAT, IWCS, STATUS )

*  Description:
*     This returns a pointer to a FrameSet describing the WCS information
*     in the given SPECX file. The current Frame is a 3D Frame with RA on 
*     axis 1, DEC on axis 2, and frequency on axis 3. The base Frame is a
*     3D GRID Frame. The parameters defining the axes are read from the 
*     SPECX extensions in the supplied SPECX map, except for the 
*     observatory location which is provided by the caller.

*  Arguments:
*     IMAP = INTEGER (Given)
*        The NDF identifier for the SPECX map file.
*     DIM( 3 ) = INTEGER (Given)
*        The dimensions of the pixel axes of the array into which the SPECX 
*        data is being placed.
*     OBSLON = DOUBLE PRECISION (Given)
*        The geodetic longitude of the observatory. Radians, positive east.
*     OBSLAT = DOUBLE PRECISION (Given)
*        The geodetic latitude of the observatory. Radians, positive north.
*     IWCS = INTEGER (Returned)
*        The returned FrameSet.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     - Various assumptions are made about the meaning of several items
*     in the SPECX extensions. These are described in the code comments.
*     - Double Sideband is always assumed

*  Authors:
*     DSB: David S. Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     21-FEB-2008 (DSB):
*        Original version, derived from CON_WCSPX in the CONVERT package.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'PRM_PAR'          ! VAL constants
      INCLUDE 'AST_PAR'          ! AST constants

*  Arguments Given:
      INTEGER IMAP
      INTEGER DIM( 3 )
      DOUBLE PRECISION OBSLON
      DOUBLE PRECISION OBSLAT

*  Arguments Returned:
      INTEGER IWCS

*  Status:
      INTEGER STATUS               ! Global status

*  Local Constants:
      DOUBLE PRECISION D2R         ! Degrees to radians conversion factor
      PARAMETER ( D2R = 0.01745329252 )
      DOUBLE PRECISION R2D         ! Radians to degrees conversion factor
      PARAMETER ( R2D = 1.0D0/D2R )
      DOUBLE PRECISION C           ! Speed of light (m/s)
      PARAMETER ( C = 2.99792458E8 )
      DOUBLE PRECISION DIAM        ! Diameter of JCMT (metres)
      PARAMETER ( DIAM = 15.0 )

*  Local Variables:
      CHARACTER CARD*80      ! FITS header card
      CHARACTER CMONTH*3     ! Month as a three-character abbreviation
      CHARACTER EPOCH*50     ! Epoch string
      CHARACTER MONTHS(12)*3 ! Months of the year.
      CHARACTER SIDEBAND*3   ! USB or LSB?
      CHARACTER SOR*10       ! Value for StdOfRest attribute
      CHARACTER SYS*10       ! Value for System attribute
      CHARACTER UTDATE*15    ! UT date of the observation
      CHARACTER UTIME*15     ! UT time of the observation
      DOUBLE PRECISION CD1   ! RA pixel size
      DOUBLE PRECISION CD2   ! DEC pixel size
      DOUBLE PRECISION CD3   ! Frequency pixel size
      DOUBLE PRECISION CRPIX1! GRID coord at centre of RA axis (degrees)
      DOUBLE PRECISION CRPIX2! GRID coord at centre of Dec axis (degrees)
      DOUBLE PRECISION CRPIX3! GRID coord at centre of FREQ axis (GHz)
      DOUBLE PRECISION CRVAL3! Frequency (GHz) at the axis 1 reference point
      DOUBLE PRECISION DDEC  ! Dec offset (arc-seconds)
      DOUBLE PRECISION DEC   ! Central Dec (degrees)
      DOUBLE PRECISION DRA   ! RA offset (seconds)
      DOUBLE PRECISION DTBYDS! Rate of change of topo freq wrt source freq
      DOUBLE PRECISION IFFREQ! IF Frequency (GHz)
      DOUBLE PRECISION MJD   ! Modified Julian Date of observation
      DOUBLE PRECISION POSANG! Position angle of Y axis (degs East of North)
      DOUBLE PRECISION RA    ! Central RA (degrees)
      DOUBLE PRECISION SRCVEL! Assumed source velocity (km/s)
      INTEGER AXES( 2 )      ! Axes to be selected from the Frame
      INTEGER BFRM           ! Pointer to new GRID Frame
      INTEGER DAY            ! Day
      INTEGER DMAP           ! An unused Mapping pointer
      INTEGER DSTAT          ! Local SLA status
      INTEGER FC             ! Pointer to AST FitsChan
      INTEGER FRM            ! Pointer to AST Frame to be added to NDF
      INTEGER FS             ! Pointer to AST FrameSet
      INTEGER HOUR           ! Hour of observation
      INTEGER IAT            ! Used length of string
      INTEGER INTT           ! Integration time in ms
      INTEGER ISOR           ! LSR identifier extracted from LSRFLG
      INTEGER ISYS           ! Spectral system identifier from LSRFLG
      INTEGER JFCEN          ! Frequency (kHz) at spectral axis centre
      INTEGER JFINC          ! Pixel size (Hz) on spectral axis 
      INTEGER JFREST         ! Rest frequency (kHz)
      INTEGER LOOP           ! Loop index
      INTEGER LSRFLG         ! Value of SPECX LSRFLG header item
      INTEGER MAP            ! Pointer to AST Mapping 
      INTEGER MIN            ! Minute of observation
      INTEGER MONTH          ! Month
      INTEGER SF             ! Pointer to AST SkyFrame
      INTEGER SKYFRM         ! Pointer to AST SkyFrame
      INTEGER SPCFRM         ! Pointer to AST SpecFrame
      INTEGER TDBFRM         ! TimeFrame describing the TDB timescale
      INTEGER TPFRM          ! SpecFrame describing Topocentric rest frame
      INTEGER TIMEFS         ! FrameSet connecting TDB abd UT1 timescales
      INTEGER UT1FRM         ! TimeFrame describing the UT1 timescale
      INTEGER YEAR           ! Year 
      LOGICAL ISDSB          ! Is this a double sideband observation?
      LOGICAL THERE          ! Does object exist?
      REAL CT                ! Product of channel spacing and integ time
      REAL DAYS              ! Time of observation as fraction of a day
      REAL SEC               ! Seconds of observation
      REAL TSYS              ! Tsys 

      DATA MONTHS /'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL',
     :             'AUG', 'SEP', 'OCT', 'NOV', 'DEC'/


*.

*  Initialise returned values.
      IWCS = AST__NULL

*  Check the inherited status. 
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Begin an AST context.
      CALL AST_BEGIN( STATUS )

*  For now, assume that all specx files are dual sideband. This is wrong
*  but good enough for testing. It's also highly likely that SSB observations
*  might like to look in the other sideband for line contamination.
*  Either this should always be true, or we should prompt for it.
      ISDSB = .TRUE.

*  First create an AST SpecFrame to represent the spectral axis. This
*  will be used as axis 1 within the Frame which is finally added to the 
*  WCS component of the output NDF.
*  ===================================================================

*  Create a [DSB]SpecFrame describing frequency in units of GHz.
      IF (ISDSB) THEN
         SPCFRM = AST_DSBSPECFRAME( 'System=freq,unit=GHz', STATUS )
      ELSE
         SPCFRM = AST_SPECFRAME( 'System=freq,unit=GHz', STATUS )
      END IF

*  Set its attributes so that they correspond to the information stored
*  in the SPECX extensions in the input map...

*  Since the DSB SpecFrame attributes can only be derived from
*  knowledge of the observed sideband which in specx requires JFINC
*  we defer setting of these attributes until JFINC and JFCEN are
*  read. [alternatively we could move those reads up]

*  Rest frequency. Convert from kHz to GHz.
      CALL NDF_XGT0I( IMAP, 'SPECX', 'JFREST(1)', JFREST, STATUS )
      CALL AST_SETD( SPCFRM, 'RestFreq', DBLE( JFREST )*1.0D-6, STATUS )

*  Source position. We create an FK4 B1950 SkyFrame which AST_SETREFPOS 
*  will use to interpret the supplied values. 
      CALL NDF_XGT0D( IMAP, 'SPECX', 'RA_DEC(1)', RA, STATUS )
      CALL NDF_XGT0D( IMAP, 'SPECX', 'RA_DEC(2)', DEC, STATUS )

      CALL NDF_XGT0D( IMAP, 'SPECX', 'DPOS(1)', DRA, STATUS )
      CALL NDF_XGT0D( IMAP, 'SPECX', 'DPOS(2)', DDEC, STATUS )
      DEC = DEC + DDEC/3600.0
      RA = RA + DRA/( 3600.0*COS( DEC*D2R ) )

      SF = AST_SKYFRAME( 'System=FK4', STATUS )
      CALL AST_SETREFPOS( SPCFRM, SF, RA*D2R, DEC*D2R, STATUS )

*  Epoch of observation. First extract the year, month and day of the 
*  UTC from the IDATE item in the SPECX extension, and convert them to 
*  integers.  Then attempt to calculate the MJD. Report an error if it
*  fails.
      CALL NDF_XGT0C( IMAP, 'SPECX', 'IDATE', UTDATE, STATUS )

      CALL CHR_CTOI( UTDATE( 1:2 ), DAY, STATUS )
      CALL CHR_CTOI( UTDATE( 8: ), YEAR, STATUS )

      CMONTH( 1:3 ) = UTDATE( 4:6 )
      CALL CHR_UCASE( CMONTH )

      MONTH = 0
      DO LOOP = 1, 12
         IF( CMONTH .EQ. MONTHS( LOOP ) ) THEN
            MONTH = LOOP
         END IF
      END DO

      CALL SLA_CALDJ( YEAR, MONTH, DAY, MJD, DSTAT )
      IF( DSTAT .NE. 0 .AND. STATUS .EQ. SAI__OK ) THEN
         STATUS = SAI__ERROR
         CALL MSG_SETC( 'D', UTDATE )
         CALL ERR_REP( 'ATL_WCSPX_ERR2', 'The ''IDATE'' item in the '//
     :                 'SPECX header has value ''^D'' which cannot '//
     :                 'be interpreted as a date.', STATUS )
         GO TO 999
      END IF

*  Now extract the hours mins and seconds fields from the ITIME header
*  item and convert to a fraction of a day.
      CALL NDF_XGT0C( IMAP, 'SPECX', 'ITIME', UTIME, STATUS )

      CALL CHR_CTOI( UTIME( 1:2 ), HOUR, STATUS )
      CALL CHR_CTOI( UTIME( 4:5 ), MIN, STATUS )
      CALL CHR_CTOR( UTIME( 7: ), SEC, STATUS )

      CALL SLA_CTF2D( HOUR, MIN, SEC, DAYS, DSTAT ) 
      IF( DSTAT .NE. 0 .AND. STATUS .EQ. SAI__OK ) THEN
         STATUS = SAI__ERROR
         CALL MSG_SETC( 'D', UTIME )
         CALL ERR_REP( 'ATL_WCSPX_ERR3', 'The ''ITIME'' item in the '//
     :                 'SPECX header has value ''^D'' which cannot '//
     :                 'be interpreted as a time.', STATUS )
         GO TO 999
      END IF

*  Add the fractional day onto the Modified Julian Date.
      MJD = MJD + DAYS

*  We need to convert this MJD from UT1 (used by specx) to TDB (used by
*  AST). Create two TimeFrames describing these two time systems. SPECX
*  does not seem to store a DUT1 value, so the default of zero will be used.
      UT1FRM = AST_TIMEFRAME( 'TimeScale=UT1', STATUS )
      CALL AST_SETD( UT1FRM, 'ObsLon', OBSLON/D2R, STATUS )
      CALL AST_SETD( UT1FRM, 'ObsLat', OBSLAT/D2R, STATUS )

      TDBFRM = AST_TIMEFRAME( 'TimeScale=TDB', STATUS )
      CALL AST_SETD( TDBFRM, 'ObsLon', OBSLON/D2R, STATUS )
      CALL AST_SETD( TDBFRM, 'ObsLat', OBSLAT/D2R, STATUS )

*  Get a Mapping that converts from UT1 to TDB, and use it to transform
*  the epoch value.
      TIMEFS = AST_CONVERT( UT1FRM, TDBFRM, ' ', STATUS )
      CALL AST_TRAN1( TIMEFS, 1, MJD, .TRUE., MJD, STATUS )

*  Format the TDB MJD into a form suitable for use with AST_SETC.
      WRITE( EPOCH, * ) 'MJD ',MJD

*  Set the Epoch attribute.
      CALL AST_SETC( SPCFRM, 'Epoch', EPOCH, STATUS )

*  Observatory position. 
      CALL AST_SETD( SPCFRM, 'ObsLon', OBSLON/D2R, STATUS )
      CALL AST_SETD( SPCFRM, 'ObsLat', OBSLAT/D2R, STATUS )
      
*  Standard of rest. In order to get consistency with plots produced by
*  SPECX, it seems that the frequency axis defined by the JFCEN and JFINC
*  SPECX extension items (created below) give the frequency in the rest
*  frame of the source. There is more info on this in the specx user
*  manual (specx_v6-3.tex) section "Notes on individual header parameters".
      CALL AST_SETC( SPCFRM, 'StdOfRest', 'Source', STATUS )

*  The source is assumed to be moving at a speed given by V_SETL(4) within 
*  the rest frame given by the bottom 4 bits of the LSRFLG extension item 
*  (0=Topocentric (called "Telluric" within SPECX), 1=kinematic LSR 
*  2=Heliocentric, 3 = geocentric). Set the source velocity rest frame.
      CALL NDF_XGT0I( IMAP, 'SPECX', 'LSRFLG', LSRFLG, STATUS)
      ISOR = MOD( LSRFLG, 16 )

      IF( ISOR .EQ. 0 ) THEN
         SOR = 'TOPO'

      ELSE IF( ISOR .EQ. 1 ) THEN
         SOR = 'LSRK'

      ELSE IF( ISOR .EQ. 2 ) THEN
         SOR = 'HELIO'

      ELSE IF( ISOR .EQ. 3 ) THEN
         SOR = 'GEO'

      ELSE IF( STATUS .EQ. SAI__OK ) THEN
         STATUS = SAI__ERROR
         CALL MSG_SETI( 'I', LSRFLG )
         CALL MSG_SETI( 'J', ISOR )
         CALL ERR_REP( 'ATL_WCSPX_ERR1', 'The ''LSRFLG'' item in the '//
     :                 'SPECX header has value ^I which specifies an '//
     :                 'unknown standard of rest value (^J).', STATUS )
         GO TO 999
      END IF      

      CALL AST_SETC( SPCFRM, 'SourceVRF', SOR, STATUS )

*  The source velocity is radio, optical or relativistic, depending on the 
*  bits 5 and 6 of the LSRFLG extension item (0=radio, 1=optical,
*  2=relativistic). Set the source velocity system.
      ISYS = LSRFLG / 16

      IF( ISYS .EQ. 0 ) THEN
         SYS = 'VRAD'

      ELSE IF( ISYS .EQ. 1 ) THEN
         SYS = 'VOPT'

      ELSE IF( ISYS .EQ. 2 ) THEN
         SYS = 'VELO'

      ELSE IF( STATUS .EQ. SAI__OK ) THEN
         STATUS = SAI__ERROR
         CALL MSG_SETI( 'I', LSRFLG )
         CALL MSG_SETI( 'J', ISYS )
         CALL ERR_REP( 'ATL_WCSPX_ERR2', 'The ''LSRFLG'' item in the '//
     :                 'SPECX header has value ^I which specifies an '//
     :                 'unknown velocity system value (^J).', STATUS )
         GO TO 999
      END IF      

      CALL AST_SETC( SPCFRM, 'SourceSys', SYS, STATUS )

*  Get the assumed velocity of the source in the rest frame and spectral
*  system obtained from LSRFLG.
      CALL NDF_XGT0D( IMAP, 'SPECX', 'V_SETL(4)', SRCVEL, STATUS )

*  If the source velocity is not zero, assign it to the SourceVel
*  attribute. It will be interpreted as a velocity within the rest frame
*  specified by the current value of SourceVRF (i.e. the rest frame extracted 
*  from LSRFLG above). 
      IF( SRCVEL .NE. 0.0 ) THEN
         CALL AST_SETD( SPCFRM, 'SourceVel', SRCVEL, STATUS )

*  If the source velocity is zero, set the StdOfRest attribute to the
*  rest frame indicated by LSRFLG.
      ELSE
         CALL AST_SETC( SPCFRM, 'StdOfRest', SOR, STATUS )
      END IF

*  Now create FITS-WCS keyword values describing the transformation
*  from GRID positions on the spectral axis into the corresponding 
*  frequency values as described by the above SpecFrame. The axis is 
*  assumed to be linear in frequency.
*  ===================================================================

*  Get the GRID coordinate at the centre of the central pixel on the 
*  third axis of the output NDF. 
      CRPIX3 = 0.5*( DIM( 3 ) + 1 )
         
*  Get the central frequency, in kHz. Convert to GHz.
      CALL NDF_XGT0I( IMAP, 'SPECX', 'JFCEN(1)', JFCEN, STATUS )
      CRVAL3 = DBLE( JFCEN )*1.0E-6

*  Get the frequency increment per pixel, in Hz. Convert to GHz.
      JFINC = 0
      CALL NDF_XGT0I( IMAP, 'SPECX', 'JFINC(1)', JFINC, STATUS)
      CD3 = DBLE( JFINC )*1.0E-9

*  The specx user manual implies that, whilst the JFCEN value is in the
*  source rest frame, the JFINC value is in the topocentric rest frame. 
*  So we need to convert JFINC from topcentric to source rest frame. Take
*  a copy of the SpecFrame and set its rest frame to topocentric.
      TPFRM = AST_COPY( SPCFRM, STATUS )
      CALL AST_SETC( TPFRM, 'StdOfRest', 'Topo', STATUS )

*  Get the Mapping from source to topocentric rest frame, and get the
*  rate of change of topocentric frequency with respect to source frequency
*  at the frequency given by JFCEN.
      DTBYDS = AST_RATE( AST_CONVERT( SPCFRM, TPFRM, ' ', STATUS ), 
     :                   CRVAL3, 1, 1, STATUS )

*  Convert the frequency increment from topocentric to source.
      CD3 = CD3/DTBYDS

*  Since this is a convenient time, configure the DSB-ness
      IF (ISDSB) THEN

         CALL AST_SETD( SPCFRM, 'DSBCentre', CRVAL3, STATUS)

*  For dual sideband instruments we need to get the IF frequency
*  This is always in GHz in specx. It must be -ve if the observed
*  sideband is upper, positive if we are in LSB
         CALL NDF_XGT0D( IMAP, 'SPECX', 'IFFREQ(1)', IFFREQ, STATUS )

*  Calculate observed sidband. SPECX uses a positive IF if we are USB,
*  negative IF if we are LSB.
*  AST requires that the LO = JFCEN + IF such that LSB implies
*  a positive IF, LSB a negative. (ie the reverse of SPECX convention)
         IF (IFFREQ .GT. 0) THEN
            SIDEBAND = 'USB'
         ELSE
            SIDEBAND = 'LSB'
         END IF
         IFFREQ = -IFFREQ

*   Set sideband and IF
         CALL AST_SETC(SPCFRM, 'SideBand', SIDEBAND, STATUS)
         CALL AST_SETD( SPCFRM, 'IF', IFFREQ, STATUS)

      END IF


*  Now create a SkyFrame describing the spatial position (RA,Dec), and
*  the 3D Mapping which goes from 3D GRID coords to (RA,Dec,Freq). 
*  ===================================================================

*  Get the central GRID coordinate on the first and second axes of the 
*  output NDF (the RA and Dec axes).
      CRPIX1 = 0.5*( DIM( 1 ) + 1 )
      CRPIX2 = 0.5*( DIM( 2 ) + 1 )

*  Does the input NDF have a SPECX_MAP extension?
      CALL NDF_XSTAT( IMAP, 'SPECX_MAP', THERE, STATUS ) 

*  If so, get the RA and Dec pixel sizes from the SPECX map. Convert from 
*  arc-seconds to degrees.
      IF( THERE ) THEN 

         CALL NDF_XGT0D( IMAP, 'SPECX_MAP', 'CELLSIZE(1)', CD1, STATUS )
         CD1 = CD1/3600.0

         CALL NDF_XGT0D( IMAP, 'SPECX_MAP', 'CELLSIZE(2)', CD2, STATUS )
         CD2 = CD2/3600.0

*  Get the position angle of the Y axis (assumed to be in degrees).
         CALL NDF_XGT0D( IMAP, 'SPECX_MAP', 'POSANGLE', POSANG, STATUS )

*  If no SPECX_MAP extension, use default values. The pixel size is
*  assumed to be equal to half the resolution of the telescope (assumed 
*  to be  JCMT with a diameter of 15 metres).
      ELSE
         CD1 = 0.5*R2D*C/(JFCEN*1000.0*DIAM)
         CD2 = CD1
         POSANG = 0.0
      END IF

*  Create an empty AST FitsChan.
      FC = AST_FITSCHAN( AST_NULL, AST_NULL, ' ', STATUS )

*  Put FITS cards into the FitsChan representing a SIN projection of the
*  sky, using the pixel sizes obtained above. It is assumed that north is
*  parallel to the third axis and east is parallel to the second axis.
*  It is assumed that the RA and DEC values are FK4 B1950. Axis 3 is the
*  spectral axis.
      CALL AST_PUTFITS( FC, ' ', .FALSE., STATUS ) 

      CARD = 'NAXIS1  = '
      IAT = 10
      CALL CHR_PUTI( DIM( 1 ), CARD, IAT )
      CALL AST_PUTFITS( FC, CARD, .FALSE., STATUS ) 

      CARD = 'NAXIS2  = '
      IAT = 10
      CALL CHR_PUTI( DIM( 2 ), CARD, IAT )
      CALL AST_PUTFITS( FC, CARD, .FALSE., STATUS ) 

      CALL AST_PUTFITS( FC, 'NAXIS3  = 1', .FALSE., STATUS ) 

      CALL AST_PUTFITS( FC, 'CTYPE1  =  ''RA---SIN''', .FALSE., STATUS ) 

      CARD = 'CRPIX1  = '
      IAT = 10
      CALL CHR_PUTD( CRPIX1, CARD, IAT )
      CALL AST_PUTFITS( FC, CARD, .FALSE., STATUS ) 

      CARD = 'CRVAL1  = '
      IAT = 10
      CALL CHR_PUTD( RA, CARD, IAT )
      CALL AST_PUTFITS( FC, CARD, .FALSE., STATUS ) 

      CARD = 'CDELT1  = '
      IAT = 10
      CALL CHR_PUTD( -CD1, CARD, IAT )
      CALL AST_PUTFITS( FC, CARD, .FALSE., STATUS ) 

      CALL AST_PUTFITS( FC, 'CTYPE2  =  ''DEC--SIN''', .FALSE., STATUS ) 

      CARD = 'CRPIX2  = '
      IAT = 10
      CALL CHR_PUTD( CRPIX2, CARD, IAT )
      CALL AST_PUTFITS( FC, CARD, .FALSE., STATUS ) 

      CARD = 'CRVAL2  = '
      IAT = 10
      CALL CHR_PUTD( DEC, CARD, IAT )
      CALL AST_PUTFITS( FC, CARD, .FALSE., STATUS ) 

      CARD = 'CDELT2  = '
      IAT = 10
      CALL CHR_PUTD( CD2, CARD, IAT )
      CALL AST_PUTFITS( FC, CARD, .FALSE., STATUS ) 

      CARD = 'CROTA2  = '
      IAT = 10
      CALL CHR_PUTD( -POSANG, CARD, IAT )
      CALL AST_PUTFITS( FC, CARD, .FALSE., STATUS ) 

      CALL AST_PUTFITS( FC, 'EQUINOX = 1950.0', .FALSE., STATUS ) 
      CALL AST_PUTFITS( FC, 'RADESYS = ''FK4''', .FALSE., STATUS ) 

      CALL AST_PUTFITS( FC, 'CTYPE3  =  ''FREQ    ''', .FALSE., STATUS ) 

      CARD = 'CRPIX3  = '
      IAT = 10
      CALL CHR_PUTD( CRPIX3, CARD, IAT )
      CALL AST_PUTFITS( FC, CARD, .FALSE., STATUS ) 

      CARD = 'CRVAL3  = '
      IAT = 10
      CALL CHR_PUTD( CRVAL3, CARD, IAT )
      CALL AST_PUTFITS( FC, CARD, .FALSE., STATUS ) 

      CARD = 'CDELT3  = '
      IAT = 10
      CALL CHR_PUTD( CD3, CARD, IAT )
      CALL AST_PUTFITS( FC, CARD, .FALSE., STATUS ) 

*  Read a FrameSet from the FitsChan. 
      CALL AST_CLEAR( FC, 'Card', STATUS )
      FS = AST_READ( FC, STATUS )

*  Get a pointer to the current Frame in this FrameSet, which will be a 
*  CmpFrame containing a SkyFrame describing the spatial positions within 
*  the map, and a 1D Frame (for the Freq axis). Extract the SkyFrame
*  (axes 1 and 2).
      AXES( 1 ) = 1
      AXES( 2 ) = 2
      SKYFRM = AST_PICKAXES( AST_GETFRAME( FS, AST__CURRENT, STATUS ),
     :                       2, AXES, DMAP, STATUS ) 

*  Set the Epoch to be the same as the SpecFrame.
      CALL AST_SETC( SKYFRM, 'Epoch', EPOCH, STATUS )

*  The Base Frame in the FrameSet will correspond to 3D GRID coordinates.
*  Get the Mapping from GRID to SPECTRUM-SKY coordinates.
      MAP = AST_GETMAPPING( FS, AST__BASE, AST__CURRENT, STATUS )

*  Create the returned FrameSet.
*  ============================================
*  Create a 3D GRID Frame, and put it in a new FrameSet.
      BFRM = AST_FRAME( 3, 'Domain=GRID,unit(1)=pixel,unit(2)=pixel,'//
     :                  'unit(3)=pixel', STATUS );
      IWCS = AST_FRAMESET( BFRM, ' ', STATUS )      

*  Construct a 3D CmpFrame describing all 3 axes. RA becomes axis 1 and DEC 
*  becomes axis 2, and the spectral axis becomes axis 3.
      FRM = AST_CMPFRAME( SKYFRM, SPCFRM, 'Title=Compound '//
     :                    'coordinates describing celestial position '//
     :                    'and spectral position', STATUS )

*  Add the CmpFrame created above into the returned FrameSet, using the
*  Mapping created above to connect it to the GRID Frame.
      CALL AST_ADDFRAME( IWCS, AST__BASE, MAP, FRM, STATUS )       

*  Set the standard of rest to the rest frame indicated by
*  the LSRFLG extension item. This was requested by JACH (rather than
*  leaving the standard of rest set to "Source").
      CALL AST_SETC( IWCS, 'StdOfRest', SOR, STATUS )

*  Export the FrameSet pointer so that it is not anulled by the following
*  call to AST_END.
      CALL AST_EXPORT( IWCS, STATUS )

 999  CONTINUE

*  End the AST context.
      CALL AST_END( STATUS )

      END
