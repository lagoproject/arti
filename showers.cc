/************************************************************************/
/*                                                                      */
/* Package:  CrkTools                                                   */
/* Module:   showers.cc                                                 */
/*                                                                      */
/************************************************************************/
/* Authors:  Hernán Asorey                                              */
/* e-mail:   asoreyh@cab.cnea.gov.ar                                    */
/*                                                                      */
/************************************************************************/
/* Comments: Change showers Id to avoid repeated numbers                */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/* 
 
Copyright 2013
Hernán Asorey
Lab DPR (CAB-CNEA), Argentina
Grupo Halley (UIS), Colombia
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

   1. Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE AUTHORS ''AS IS'' AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
NO EVENT SHALL LAB DPR OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are
those of the authors and should not be interpreted as representing
official policies, either expressed or implied, of Lab DPR.

*/
/************************************************************************/
#define VERSION "v3r0"

#define _FILE_OFFSET_BITS 64
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <fstream>
#include <math.h>

using namespace std;

//global
int iverbose = 0, iforce = 0, ifilter = 0, icurve = 0, idistance=0, ianalysis=0, inorm = 0, igeo = 0; 
int particle=0; 
bool print=true;
FILE *fi, *shw, *hst, *dst;
double x, y, z, h, hInM;
double r_earth=637131500.;
double GeV2keV=1.0e6;
double maxPInGeV = 1.0e7; //10^16 eV is the upper limit for p particles (not expected)
double cm2m=0.01;
double maxDInM = 6e4; // 60 km should be enough 
int cGeoCdef=3;
int cGeoC = cGeoCdef; // column from geomagnetic cutoff file


double resdist=25., resolution = 25., area=0., fluxTime=0.;

const int masaN = 27;

int masaI[masaN] = {1, 14, 402, 703, 904, 1105, 1206, 1407, 1608, 1909, 2010, 2311, 2412, 2713, 2814, 3115, 3216, 3517, 4018, 3919, 4020, 4521, 4822, 5123, 5224, 5525, 5626};

double masas[masaN] = {0., 0.938272, 3.73338, 6.53478, 8.39429, 10.25361, 11.17879, 13.04507, 14.89833, 17.68991, 18.61736, 21.40802, 22.33628, 25.12634, 26.05532, 28.84497, 29.77460, 32.56398, 37.21075, 36.28343, 37.21424, 41.86053, 44.64837, 47.44020, 48.36813, 51.15981, 52.08852};


int Open(char *nfi) {
  char tmpc[256];
  if (strncmp(nfi+strlen(nfi)-4,".bz2",4)==0) {
    if (iverbose)
      fprintf(stderr,"File '%s' ending by bz2, reading it via bzip2\n",nfi);
    snprintf(tmpc,256,"bzip2 -d -c %s",nfi);
    fi=popen(tmpc,"r");
  }
  else if((fi=fopen(nfi,"r")) == NULL) {
    if (iverbose)
      fprintf(stderr,"Can't open file '%s' - Switching to SDTIN\n",nfi);
    fi=stdin;
  }
  return 1;
}

void Usage(char *prog, int iverbose=0) {
  cout << endl << "shower.cc, from CrkTools version " << VERSION << endl<< endl;
  cout << "  Check secondaries file and change shower Id. This allows to process secondaries" << endl << "  within the detector simulation and handle mini showers." << endl;
  cout << "  Usage: " << prog << " [flags] raw_file" << endl;
  cout << "    If 'raw_file' does not exits, switch to STDIN and use raw_file as" << endl;
  cout << "    basename for output file." << endl;
  cout << "    flags:"<<endl;
  cout << "      -s <type>       : filter secondaries by type: 1: EM, 2: MU, 3: HD"<<endl;
  cout << "      -a <n>          : Energy distribution of secondaries per type, with <n> bins per decade."<<endl;
  cout << "      -d <n>          : Distance distribution of secondaries per type, with <n> bins per decade."<<endl;
  cout << "      -n <a> <t>      : Normalize energy distribution in particles/(m2 s bin), <a>=detector area (m2), <t> = flux time (s)." <<endl;
  cout << "      -c <obs_lev>    : Enable curved mode: x'y' will be converted to local coordinates xy"<<endl;
  cout << "                        Observation level (<obs_lev>) should be given in m a.s.l." << endl;
  cout << "      -g <file> <col> : Include geomagentic effects. Read  rigidities from column <R> of <file>. Default R= " << cGeoCdef <<endl;
  cout << "                        3=R_U, 4=R_C 5=R_L"<<endl;
  cout << "      -f              : Force analysis without enable curved mode (WARNING)"<<endl;
  cout << "      -v              : Enable verbose output (each -v increases verbosity level)"<< endl;
  cout << "      -?              : prints help and exits"<<endl << endl;
  if (iverbose) {
    // verbose help
  }
  exit(1);
}

void curved(double xp, double yp) {
  double d = r_earth + h;
  double t = sqrt(xp*xp + yp*yp)/d;
  double f = atan2(yp,xp);
  z = (d*cos(t) - r_earth)*cm2m;
  d *= sin(t);
  x = d*cos(f)*cm2m;
  y = d*sin(f)*cm2m;
}

inline double momemtum(double px, double py, double pz) {
  return (GeV2keV*sqrt(px*px+py*py+pz*pz));
}

inline double distance(double r1, double r2, double r3) {
  return (sqrt(r1*r1+r2*r2+r3*r3));
}

inline double log10(double x) {
  return (log(x)/log(10.));
}

int main (int argc, char *argv[]) {

  char nfi[256]; // filename container
  char nfg[256]; // geomagnetic effects file
  char *ifiname=NULL; // input
  char line[256];
  int id = 0;

  x = y = z = h = 0.;
  // reading arguments from command line
  for (int i=1;i<argc;i++) {
    char *tmparg=argv[i];
    if (*tmparg=='-') {
      switch (*(tmparg+1)) {
        case 's':
          ifilter=1;
          i++;
          particle=atoi(argv[i]);
          break;
        case 'a':
          ianalysis=1;
          if (atof(argv[i+1])) {
            i++;
            resolution = atof(argv[i]);
          }
          break;
        case 'd':
          idistance=1;
          if (atof(argv[i+1])) {
            i++;
            resdist = atof(argv[i]);
          }
          break;
        case 'n':
          inorm = 1;
          if (atof(argv[i+1]) && atof(argv[i+2])) {
            i++;
            area=atof(argv[i]);
            i++;
            fluxTime=atof(argv[i]);
          }
          else {
            fprintf(stderr, " Error: for -n option you must provide detector area and flux time\n");
            Usage(argv[0]);
            break;
          }
          break;
        case 'f':
          iforce=1;
          break;
        case 'v':
          iverbose++;
          break;
        case 'c':
          icurve=1;
          i++;
          h=(double)(atof(argv[i])*100.); // calculation is in cm...
          hInM=h*cm2m;
          break;
        case 'g':
          igeo=1;
          i++;
          snprintf(nfg,256,"%s",argv[i]);
          i++;
          cGeoC = atoi(argv[i]) - 1;
          if (!(cGeoC>1 && cGeoC<5)) {
            fprintf(stderr, " Error: for -g option you must provide file name and the selected rigidity column (3 to 5)\n");
            Usage(argv[0]);
            break;
          }
          break;
        case '?':
        default:
          Usage(argv[0]);
          break;
      }
    }
    else 
      ifiname=argv[i];
  }
  if (!ifiname) {
    fprintf(stderr, "\n Error: Missing filename\n\n");
    Usage(argv[0]);
  }
  if (ianalysis || idistance) {
    if (!icurve) {
      if (!iforce) {
        fprintf(stderr, "\n Error: analysis mode require curved mode enabled. \nUse -f (force) to force analysis (use at your own risk)\n\n"); 
        Usage(argv[0]);
      }
    }
  }
  int check = 0;
  int iGeoZ = 0;
  int iGeoA = 0;
  int iGeoN = 0;

  double rGeoZ = 6.;
  double rGeoA = 25.;
  int nGeoZ = int(90. / rGeoZ) + 1;
  int nGeoA = int(360. / rGeoA) + 1; 
  double gGeoC[nGeoZ][nGeoA];
  double g[5];
  if (igeo) {
    FILE *fg; 
    // reading geo file
    if((fg=fopen(nfg,"r")) == NULL) {
      fprintf(stderr, "\nError: Can't open geomagnetic file\n\n");
      Usage(argv[0]);
    }
    while(fgets(line,250,fg)) {
      if (line[0] == '#')
        continue;
      do { // read
        check=sscanf(line, "%le %le %le %le %le\n", &g[0], &g[1], &g[2], &g[3], &g[4]); 
      } while (check != 5);
      iGeoZ = int(g[0]/rGeoZ);
      iGeoA = int(g[1]/rGeoA);
      gGeoC[iGeoZ][iGeoA] = g[cGeoC];
      iGeoN++;
    }
  }
  if (iverbose && igeo)
    fprintf(stderr,"Read %d rigidity cut-off values from column %d of file '%s'\n",iGeoN, cGeoC+1, nfg);
  //open input
  snprintf(nfi,256,"%s",ifiname);
  Open(nfi);
  //open output
  char *ifile2;
  char ifile[256];
  ifile2=ifiname;
  //remove dirs
  if (strrchr(ifile2,'/')!=NULL) {
    ifile2=strrchr(ifile2,'/')+1;
  }
  snprintf(ifile, 256,"%s",ifile2);
  if (strrchr(ifile,'.')!=NULL) {
    if (strncmp(strrchr(ifile,'.'),".bz2",4)==0) { // remove .bz2 if present
      *(strrchr(ifile,'.'))='\0';
    }
  }
  if (strrchr(ifile,'.')!=NULL) {
    if (strncmp(strrchr(ifile,'.'),".dat",4)==0) { // remove .dat if present
      *(strrchr(ifile,'.'))='\0';
    }
  }
  // open output file (.bz2) via popen
  snprintf(nfi,256,"bzip2 -9z > %s.shw.bz2",ifile);
  if ((shw = popen(nfi,"w"))==NULL) {
    fprintf(stderr,"Failed to open compressed output file. Abort.\n");
    exit(1);
  }
  if (ianalysis) {
    snprintf(nfi, 256, "%s.hst", ifile);
    if ((hst = fopen(nfi,"w"))==NULL) {
      fprintf(stderr,"Failed to open hst (energy histogram) file. Abort.\n");
      exit(1);
    }
  }
  if (idistance) {
    snprintf(nfi, 256, "%s.dst", ifile);
    if ((dst = fopen(nfi,"w"))==NULL) {
      fprintf(stderr,"Failed to open dst (distance histogram) file. Abort.\n");
      exit(1);
    }
  }

  fprintf(shw, "# # # shw\n");
  if (icurve)
    fprintf(shw, "# # CURVED mode is ENABLED and observation level is %.0lf m a.s.l.\n", h/100.);
  if (ifilter)
    fprintf(shw, "# # FILTER mode is ENABLED and only shows COMPONENT %d\n", particle);
  if (igeo)
    fprintf(shw, "# # Geomagnetic effects were included: %d values were read from column %d of file %s\n", iGeoN, cGeoC+1, nfg);

  fprintf(shw, "# # This is the Secondaries file - CrkTools %s\n", VERSION);
  fprintf(shw, "# # 12 column format is:\n");
  if (icurve)
    fprintf(shw, "# # CorsikaId px py pz x y z shower_id prm_id prm_energy prm_theta prm_phi\n");
  else
    fprintf(shw, "# # CorsikaId px py pz x' y' t shower_id prm_id prm_energy prm_theta prm_phi\n");
  if (ianalysis) {
    fprintf(hst, "# # # hst\n");
    if (iforce)
      fprintf(hst, "# # # WARNING: force mode is enable. Analysis done in FLAT mode.\n");
    if (icurve)
      fprintf(hst, "# # CURVED mode is ENABLED and observation level is %.0lf m a.s.l.\n", h/100.);
    if (igeo)
      fprintf(hst, "# # Geomagnetic effects were included: %d values were read from file %s\n", iGeoN, nfg);
    fprintf(hst, "# # This is the Histogram of secondary energy file - CrkTools %s\n", VERSION);
    fprintf(hst, "# # Logaritmic energy scale. Resolution used: %d bins per energy decade\n", int(resolution));
    if (inorm)
      fprintf(hst, "# # Number of particles are divided by detector area (%.4f m^2) and flux time (%.2f s)\n", area, fluxTime);
    fprintf(hst, "# # 14 column format is:\n");
    fprintf(hst, "# # p_in_bin(GeV) N_phot N_e+ N_e- N_mu+ N_mu- N_pi0 N_pi+ N_pi- N_n N_p N_pbar N_others Total_per_bin\n");
      //1=foton, 2=e+, 3=e-, 5=mu+, 6=mu-, 7=pi0, 8=pi+, 9=pi-, 13=n, 14=p, 15=bar-p, other
  }
  if (idistance) {
    fprintf(dst, "# # # dst\n");
    if (iforce)
      fprintf(dst, "# # # WARNING: force mode is enable. Analysis done in FLAT mode.\n");
    if (icurve)
      fprintf(dst, "# # CURVED mode is ENABLED and observation level is %.0lf m a.s.l.\n", h/100.);
    if (igeo)
      fprintf(dst, "# # Geomagnetic effects were included: %d values were read from file %s\n", iGeoN, nfg);
    fprintf(dst, "# # This is the Histogram of secondary distance file - CrkTools %s\n", VERSION);
    fprintf(dst, "# # Logaritmic distance scale. Resolution used: %d bins per distance decade\n", int(resolution));
    if (inorm)
      fprintf(dst, "# # Number of particles are divided by detector area (%.4f m^2) and flux time (%.2f s)\n", area, fluxTime);
    fprintf(dst, "# # 14 column format is:\n");
    fprintf(dst, "# # distance_in_bin(m) N_phot N_e+ N_e- N_mu+ N_mu- N_pi0 N_pi+ N_pi- N_n N_p N_pbar N_others Total_per_bin\n");
      //1=foton, 2=e+, 3=e-, 5=mu+, 6=mu-, 7=pi0, 8=pi+, 9=pi-, 13=n, 14=p, 15=bar-p, other
  }
  if (iverbose) {
    fprintf (stderr, "Verbosity level set to: %d.\n", iverbose);
    if (iverbose > 2) 
      fprintf (stderr, "verbosity %d: Send basic information to stderr\nverbosity %d: Discarded particles due to geomagnetic effect to stderr\nverbosity %d: Allowed particles to stdout.\n", iverbose, iverbose, iverbose);
    else if (iverbose > 1) 
      fprintf (stderr, "verbosity %d: Send basic information to stderr\nverbosity %d: Discarded particles due to geomagnetic effect to stderr\n", iverbose, iverbose);
    else
      fprintf (stderr, "verbosity %d: Send basic information to stderr\n", iverbose);
  }
  // stop talking, let's work
  double d[12];
  int nbin=12, ibin=0, nloge=0, iloge=0;
  int nlogd=0, ilogd=0;
  double lp=0., ld=0.;
  nloge = int(log10(GeV2keV*maxPInGeV)*resolution);
  long int histoe[nloge][nbin];
  long int nid[nbin], nle[nloge];
  nlogd = int(log10(maxDInM)*resdist);
  long int histod[nlogd][nbin];
  long int nld[nlogd];
  long int maxDerr = 0, maxEerr = 0;
  int prmId, prmX, prmZ, prmA;
  double prmEn, prmTh, prmPh;
  double prmMa, prmIm;
  bool prmGeo = true;
  long int geoDisShw = 0, geoDisSec = 0;
  long int totpart=0, totbin = 0;
  int minbine=10000000, maxbine=0;
  int minbind=10000000, maxbind=0;
  for (int i=0; i<nbin; i++) {
    for (int j=0; j<nloge; j++) {
      histoe[j][i] = 0;
    }
    for (int j=0; j<nlogd; j++) {
      histod[j][i] = 0;
    }
    nid[i] = 0;
  }
  for (int j=0; j<nloge; j++)
    nle[j] = 0;
  for (int j=0; j<nlogd; j++)
    nld[j] = 0;
   
  long int lines = 0, ps = 0, shower_id = 0;
  while(fgets(line,250,fi)) {
    if (!(++lines % 10000))
      fprintf (stderr, "%12ld\r", lines);
    if (line[0] == '#') {  // comments? meta-data? for now, just skipping
      continue;
    }
    do { // read
      check=sscanf(line, "%lf %le %le %le %le %le %le %lf %lf %le %lf %lf\n", &d[0], &d[1], &d[2], &d[3], &d[4], &d[5], &d[6], &d[7], &d[8], &d[9], &d[10], &d[11]);
    } while (check != 12);

    if (d[0]<1)
      continue;

    if (d[7] != ps) { // shower_id
      prmGeo = true;
      shower_id++;
      ps=d[7];
      //checking for geomagnetic effects
      if (igeo) {
        prmId=d[8];
        if (prmId>1) { // only check for charged particles (photons=1)
          prmEn=d[9];
          prmTh=d[10];
          //CORSIKA System: -180 to +180 , 0=N, +90=E, counterclockwise
          //MAGCOS  System: 0 to 360 , 0=N, +90=E, clockwise.
          //Wonderful...
          //So... if CRK>=0, MAGCOS=CORSIKA...
          if (d[11] >= 0.) 
            prmPh=d[11];
          //...else, MAGCOS=360+CORSIKA (CRK < 0)
          else
            prmPh=360.+d[11];
          // primary Z and mass
          if (prmId==14) { // protons, special case
            prmA = 1;
            prmZ = 1;
          }
          else if (prmId>100) { // nuclei
            prmA = int(prmId/100.);
            prmZ = int(prmId - prmA * 100.);
          }
          prmX = -1;
          for (int i=0; i<masaN; i++)
            if (prmId==masaI[i])
              prmX = i;
          if (prmX < 0) {
            fprintf(stderr, " Error: Can't find primary. PrmId: %04d. Please check. \nLine: %s\n", prmId, line);
            exit(1);
          }
          prmMa=masas[prmX];
          prmIm = sqrt(prmEn*prmEn - prmMa*prmMa);
          iGeoZ = int(prmTh/rGeoZ);
          iGeoA = int(prmPh/rGeoA);
          if ((prmIm/prmZ) < gGeoC[iGeoZ][iGeoA]) {
            prmGeo = false;
            geoDisShw++;
          }
        }
      }
    }
    if (prmGeo) {
      if (igeo)
        if (iverbose>2) 
          fprintf(stderr,"1 %04d %.2f %.2f %.3f %.3f %.3f %.3f %.3f\n", prmId, prmTh, prmPh, prmEn, prmMa, prmIm, prmIm/prmZ, gGeoC[iGeoZ][iGeoA]); 
      id=int(d[0]);
      print=false;
      if (ifilter) {
        switch (particle) {
          case 1:
            if (id>0 && id<3)
              print=true;
            break;
          case 3:
            if (id>6)
              print=true;
            break;
          case 2:
          default:
            if (id>4 && id<7)
              print=true;
            break;
        }
      }
      else
        print=true;
  
      x = d[4];
      y = d[5];
      z = d[6];
      if (icurve) {
        curved(d[4],d[5]);
      }
      else {
        x *= cm2m;
        y *= cm2m;
        z *= cm2m;
      }
      if (print) {
        do {
          check=fprintf(shw, "%04d %+.5le %+.5le %+.5le %+.5le %+.5le %+.5le %08ld %04d %+.5le %+07.3lf %+08.3lf\n", id, d[1], d[2], d[3], x, y, z, shower_id, (int)d[8], d[9], d[10], d[11]);
        } while (check<=0);
        totpart++;
      }
      if (ianalysis || idistance) {
        switch (id) {
        //1=foton, 2=e+, 3=e-, 5=mu+, 6=mu-, 7=pi0, 8=pi+, 9=pi-, 13=n, 14=p, 15=bar-p, other
          case 1:
            ibin=0; //photon
            break;
          case 2:
            ibin=1; //e+
            break;
          case 3:
            ibin=2; //e-
            break;
          case 5:
            ibin=3; //mu+
            break;
          case 6:
            ibin=4; //mu-
            break;
          case 7: 
            ibin=5; //pi0
            break;
          case 8: 
            ibin=6; //pi+
            break;
          case 9: 
            ibin=7; //pi-
            break;
          case 13: 
            ibin=8; //n
            break;
          case 14: 
            ibin=9; //p+
            break;
          case 15: 
            ibin=10; //p-
            break;
          default:
            ibin=11; //other hadrons
            break;
        }
        if (ianalysis) {
          lp = log10(momemtum(d[1], d[2], d[3]));
          iloge=int(lp*resolution);
          if (iloge > nloge) {
            iloge=nloge;
            maxEerr++;
            if (iverbose>1)
              cerr << "Warning! Particle momemtum is " << momemtum(d[1], d[2], d[3]) << "which is bigger than " << maxPInGeV << " GeV. Should check. \nLine: " << line << endl;
          }
          if (iloge < minbine)
            minbine=iloge;
          else if (iloge > maxbine)
            maxbine=iloge;
          histoe[iloge][ibin]++;
          nle[iloge]++;
        }
        if (idistance) {
          ld = log10(distance(x, y, (z-hInM)));
          if (ld < 0.)
            ld = 0.;
//          cout 
//            << distance(x, y, (z-hInM)) << endl;
          ilogd=int(ld*resdist);
          if (ilogd > nlogd) {
            ilogd=nlogd;
            maxDerr++;
	    if (iverbose>1)
              cerr << "Warning! Particle distance is " << distance(x,y,z) << " m, which is bigger than " << maxDInM << " m. Should check. \nLine: " << line << endl;
          }
          if (ilogd < minbind)
            minbind=ilogd;
          else if (ilogd > maxbind)
            maxbind=ilogd;
          histod[ilogd][ibin]++;
          nld[ilogd]++;
        }
        nid[ibin]++;
        totbin++;
      }
    }
    else {
      geoDisSec++;
      if (iverbose>1) 
        fprintf(stdout,"0 %04d %.2f %.2f %.3f %.3f %.3f %.3f %.3f\n", prmId, prmTh, prmPh, prmEn, prmMa, prmIm, prmIm/prmZ, gGeoC[iGeoZ][iGeoA]);
    }
  }
  if (iverbose)
    if (igeo)
      fprintf(stderr,"Including geomagnetic effects, %ld secondaries from %ld showers were discarded.\n", geoDisSec, geoDisShw);

  double p=0.,r=0;
  double norm=area*fluxTime;

  if (ianalysis) {
    for (int i=minbine; i<=maxbine; i++) {
      p=pow(10., (i/resolution))/GeV2keV;
      fprintf(hst, "%.6e ", p);
      for (int j=0; j<nbin; j++) {
        if (inorm)
          fprintf(hst, "%.7e ", histoe[i][j]/norm);
        else
          fprintf(hst, "%ld ", histoe[i][j]);
      }
      if (inorm)
        fprintf(hst, "%.7e\n", nle[i]/norm);
      else
        fprintf(hst, "%ld\n", nle[i]);
    }
    fprintf(hst, "#TOT: ");
    for (int j=0; j<nbin; j++) 
      fprintf(hst, "%ld ", nid[j]);
    fprintf(hst, "\n");
    if (inorm) {
      fprintf(hst, "#TOT_NORM: ");
      for (int j=0; j<nbin; j++) 
        fprintf(hst, "%.7e ", nid[j]/norm);
      fprintf(hst, "\n");
    }
    double tot = totbin * 1.0;
    fprintf(hst, "# FRACTIONS: ");
    for (int j=0; j<nbin; j++) 
      fprintf(hst, "%02.3f ", nid[j]/tot);
    fprintf(hst, "\n");
    fprintf(hst, "# Total number of binned particles: %ld", totbin);
    if (inorm) 
      fprintf(hst, " (corresponding to $%.2f$\\,particles\\, m$^{-2}$\\,s$^{-1}$.)", tot/norm);
    fprintf(hst, "\n");
    fprintf(hst, "# Totals: EM:MU:NE:HD= %ld:%ld:%ld:%ld\n", (nid[0]+nid[1]+nid[2]), (nid[3]+nid[4]), (nid[8]), (nid[5]+nid[6]+nid[7]+nid[9]+nid[10]+nid[11]));
    fprintf(hst, "# Ratios: EM:MU:NE:HD= %02.3f:%02.3f:%02.3f:%02.3f\n", (nid[0]+nid[1]+nid[2])/tot, (nid[3]+nid[4])/tot, (nid[8])/tot, (nid[5]+nid[6]+nid[7]+nid[9]+nid[10]+nid[11])/tot);
  }
  if (idistance) {
    for (int i=minbind; i<=maxbind; i++) {
      r=pow(10., (i/resdist));
      fprintf(dst, "%.6e ", r);
      for (int j=0; j<nbin; j++) {
        if (inorm)
          fprintf(dst, "%.7e ", histod[i][j]/norm);
        else
          fprintf(dst, "%ld ", histod[i][j]);
      }
      if (inorm)
        fprintf(dst, "%.7e\n", nld[i]/norm);
      else
        fprintf(dst, "%ld\n", nld[i]);
    }
    fprintf(dst, "#TOT: ");
    for (int j=0; j<nbin; j++)
      fprintf(dst, "%ld ", nid[j]);
    fprintf(dst, "\n");
    if (inorm) {
      fprintf(dst, "#TOT_NORM: ");
      for (int j=0; j<nbin; j++) 
        fprintf(dst, "%.7e ", nid[j]/norm);
      fprintf(dst, "\n");
    }
    double tot = totbin * 1.0;
    fprintf(dst, "# FRACTIONS: ");
    for (int j=0; j<nbin; j++) 
      fprintf(dst, "%02.3f ", nid[j]/tot);
    fprintf(dst, "\n");
    fprintf(dst, "# Total number of binned particles: %ld", totbin);
    if (inorm) 
      fprintf(dst, " (corresponding to $%.2f$\\,particles\\, m$^{-2}$\\,s$^{-1}$.)", tot/norm);
    fprintf(dst, "\n");
    fprintf(dst, "# Totals: EM:MU:NE:HD= %ld:%ld:%ld:%ld\n", (nid[0]+nid[1]+nid[2]), (nid[3]+nid[4]), (nid[8]), (nid[5]+nid[6]+nid[7]+nid[9]+nid[10]+nid[11]));
    fprintf(dst, "# Ratios: EM:MU:NE:HD= %02.3f:%02.3f:%02.3f:%02.3f\n", (nid[0]+nid[1]+nid[2])/tot, (nid[3]+nid[4])/tot, (nid[8])/tot, (nid[5]+nid[6]+nid[7]+nid[9]+nid[10]+nid[11])/tot);
  }
  // say goodbye
  cerr << "Selected particles: " << totpart << ", showers: " << shower_id << ", lines: " << lines << endl;
  fprintf(shw, "# # Selected particles: %ld, showers: %ld, lines: %ld\n", totpart, shower_id, lines);
  pclose(shw);
  if (ianalysis) {
    if (maxEerr)
      fprintf(hst, "# # WARNING: %ld particles (%.1f%%) overpass max energy bin (located at last bin)\n", maxEerr, (100.*maxEerr)/totpart);
    fprintf(hst, "# # Selected particles: %ld (binned, %ld), showers: %ld, lines: %ld\n", totpart, totbin, shower_id, lines);
    fclose(hst);
  }
  if (idistance) {
    if (maxDerr)
      fprintf(dst, "# # WARNING: %ld particles (%.1f%%) overpass max distance bin (located at last bin)\n", maxDerr, (100.*maxDerr)/totpart);
    fprintf(dst, "# # Selected particles: %ld (binned, %ld), showers: %ld, lines: %ld\n", totpart, totbin, shower_id, lines);
    fclose(dst);
  }
}
