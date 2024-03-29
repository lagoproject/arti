c /************************************************************************/
c /* Package:  ARTI                                                       */
c /* Module:   lagocrkthin.f                                              */
c /************************************************************************/
c /* Authors:  J.Oehlschlaeger, D. Heck, 01 Sep 2011, see below           */
c /* Adapted:  Hernán Asorey, with permission                             */
c /* e-mail:   hernan.asoreyh@iteda.cnea.gov.ar                           */
c /************************************************************************/
c /************************************************************************/
c /* Comments: Read corsika output (DAT files, thin version, not compact) */
c /*           and print all blocks to stdout and info data to stderr     */
c /************************************************************************/
c /*
c LICENSE BSD-3-Clause
c Copyright (c) 2015
c The LAGO Collaboration
c https://lagoproject.net
c All rights reserved.
c 
c Redistribution and use in source and binary forms, with or without
c modification, are permitted provided that the following conditions are
c met:
c 
c    1. Redistributions of source code must retain the above copyright
c       notice, this list of conditions and the following disclaimer.
c 
c    2. Redistributions in binary form must reproduce the above copyright
c       notice, this list of conditions and the following disclaimer in the
c       documentation and/or other materials provided with the distribution.
c 
c THIS SOFTWARE IS PROVIDED BY THE AUTHORS ''AS IS'' AND ANY EXPRESS OR IMPLIED
c WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
c MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
c NO EVENT SHALL LAB DPR OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
c INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
c (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
c SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
c HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
c STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
c ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
c POSSIBILITY OF SUCH DAMAGE.
c 
c The views and conclusions contained in the software and documentation are
c those of the authors and should not be interpreted as representing
c official policies, either expressed or implied, of the LAGO Collaboration.
c /************************************************************************/
c  based on:
c  c o r s i k a r e a d . f  (with THINNING)
c           ====================================================
c                 READ  AND  PRINT  CORSIKA  SHOWER  DATA
c           ====================================================
c                f77 -fbounds-check corsikaread.f -o corsikaread
c           gfortran -fbounds-check corsikaread.f -o corsikaread
c     Output format for particle output (blocklength = 22932+8 fixed)
c     each block consists of 21 subblocks of 273 words.
c----------------------------------------------------------------------
c     J.Oehlschlaeger, D. Heck, 01 Sep 2011 
c=======================================================================
c     VERSION=v1r9
      PROGRAM LAGOCRKTHIN 
      CHARACTER CHV(6552)*4,CIDENT*4,CDAT*70,CBLK*70
      DIMENSION PDATA(6552)
      EQUIVALENCE (CHV(1),PDATA(1))
      COMMON /CHARS/CHV,CDAT,CBLK,CIDENT
      CBLK='                                                  '
      CDAT=CBLK
      IREC=0
      IEVT=0
      IR=0
 
C--READ FILE NAME-------------------------------------------------------
      READ(*,428,END=440,ERR=439) CDAT
  428 FORMAT(A)
  429 CONTINUE
      WRITE(0,430) CDAT
  430 FORMAT(1H ,'READ DATA FROM FILE = ',A)
      OPEN(UNIT=3,FILE=CDAT,STATUS='OLD',FORM='UNFORMATTED')
* - - - - - - read data records with 6552 words - - - -
  431 CONTINUE
      IREC = IREC + 1
      READ(UNIT=3,ERR=434,END=433) PDATA
      if ( mod(irec,100) .eq. 0 ) 
     +   WRITE(0,*)'         HAVE READ RECORD NR.',IREC,'AT EVENT',IEVT
C-----------loop over subblocks-----------------------------------------
      DO    LIA=1,6552,312
        CIDENT(1:1) = CHV(LIA)(1:1)
        CIDENT(2:2) = CHV(LIA)(2:2)
        CIDENT(3:3) = CHV(LIA)(3:3)
        CIDENT(4:4) = CHV(LIA)(4:4)
        IF (PDATA(LIA).GE.211284.0 .AND.
     +      PDATA(LIA).LE.211286.0) THEN
          CIDENT = 'RUNH'
          WRITE(0,*)'RUNH'
        ENDIF
        IF (PDATA(LIA).GE.217432.0 .AND.
     +      PDATA(LIA).LE.217434.0) THEN
          CIDENT = 'EVTH'
          WRITE(0,*)'EVTH'
        ENDIF
        IF (PDATA(LIA).GE. 52814.0 .AND.
     +      PDATA(LIA).LE. 52816.0) THEN
          CIDENT = 'LONG'
          WRITE(0,*)'LONG'
        ENDIF
        IF (PDATA(LIA).GE.  3396.0 .AND.
     +      PDATA(LIA).LE.  3398.0) THEN
          CIDENT = 'EVTE'
          WRITE(0,*)'EVTE'
        ENDIF
        IF (PDATA(LIA).GE.  3300.0 .AND.
     +      PDATA(LIA).LE.  3302.0) THEN
          CIDENT = 'RUNE'
          WRITE(0,*)'RUNE'
        ENDIF
C-----------which kind of block is it?----------------------------------
        IF ( CIDENT.EQ.'RUNH' .OR. CIDENT.EQ.'RUNE' .OR. 
     +       CIDENT.EQ.'LONG' .OR. CIDENT.EQ.'EVTH' .OR. 
     +                             CIDENT.EQ.'EVTE' ) THEN
          CHV(LIA) = CIDENT
          IF     ( CIDENT .EQ. 'RUNH' ) THEN
C----------------subblock run header------------------------------------
            PDATA(LIA) = 11111111.
            DO    IL=LIA,LIA+311,8
              WRITE(6,'(1P,8E13.5)') (PDATA(II+IL),II=0,7)
            ENDDO
          ELSEIF ( CIDENT .EQ. 'EVTH' ) THEN
C----------------subblock event header----------------------------------
            PDATA(LIA) = 33333333.
            DO    IL=LIA,LIA+311,8
              WRITE(6,'(1P,8E13.5)') (PDATA(II+IL),II=0,7)
            ENDDO
C----------------subblock longitudinal data-----------------------------
          ELSEIF ( CIDENT .EQ. 'LONG' ) THEN
            PDATA(LIA) = 55555555.
            DO    IL=LIA,LIA+311,8
              WRITE(6,'(1P,8E13.5)') (PDATA(II+IL),II=0,7)
            ENDDO
C----------------subblock event end-------------------------------------
          ELSEIF ( CIDENT .EQ. 'EVTE' ) THEN
            PDATA(LIA) = 77777777.
            DO    IL=LIA,LIA+311,8
              WRITE(6,'(1P,8E13.5)') (PDATA(II+IL),II=0,7)
            ENDDO
C----------------subblock run end---------------------------------------
          ELSEIF ( CIDENT .EQ. 'RUNE' ) THEN
            PDATA(LIA) = 99999999.
            DO    IL=LIA,LIA+311,8
              WRITE(6,'(1P,8E13.5)') (PDATA(II+IL),II=0,7)
            ENDDO
            GOTO 929
          ENDIF
        ELSE
C-----------subblock with particle data---------------------------------
          DO    IL=LIA,LIA+311,8
            WRITE(6,'(1P,E16.8,7E13.5)') (PDATA(II+IL),II=0,7)
          ENDDO
        ENDIF
      ENDDO

  929 CONTINUE
      GOTO 431
 
C--END OF TEST----------------------------------------------------------
  433 CONTINUE
      WRITE(0,*)'         LAST RECORD ',irec-1
      CLOSE(UNIT=3)
      STOP
  434 CONTINUE
      WRITE(0,*)'         READ ERROR ON UNIT 3'
      WRITE(0,*)'         READ ERROR ON UNIT 3 (', IR, ') ON FILE ',CDAT
      IR=IR+1;
      IF ( IR < 100 ) THEN
        GOTO 431
      ELSE
        CLOSE(UNIT=3)
        STOP
      ENDIF
  439 CONTINUE
      WRITE(0,*)'         READ ERROR ON STANDARD INPUT'
      GOTO 429
  440 CONTINUE
      WRITE(*,*)'         READ END ON STANDARD INPUT'
      STOP
      END
