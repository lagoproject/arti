/************************************************************************/
/*                                                                      */
/* Package:  ARTI                                                       */
/* Module:   showers.cc                                                 */
/*                                                                      */
/************************************************************************/
/* Authors:  Hernán Asorey                                              */
/* e-mail:   hernan.asorey@iteda.cnea.gov.ar                            */
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
#define VERSION "v1r0"

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
FILE *fi, *pri, *hst;
double x, y, z, h, hInM;
double r_earth=637131500.;
double GeV2keV=1.0e6;
double kev2GeV=1.0e-6;
double maxPInGeV = 1.0e7; //10^16 eV is the upper limit for p particles (not expected)
double cm2m=0.01;
double maxDInM = 5e4; // 50 km should be enough 
int cGeoCdef=3;
int cGeoC = cGeoCdef; // column from geomagnetic cutoff file


double resdist=25., resolution = 25., area=0., fluxTime=0.;

const int masaN = 27;

int masaI[masaN] = {1, 14, 402, 703, 904, 1105, 1206, 1407, 1608, 1909, 2010, 2311, 2412, 2713, 2814, 3115, 3216, 3517, 4018, 3919, 4020, 4521, 4822, 5123, 5224, 5525, 5626};

double masas[masaN] = {0., 0.938272, 3.73338, 6.53478, 8.39429, 10.25361, 11.17879, 13.04507, 14.89833, 17.68991, 18.61736, 21.40802, 22.33628, 25.12634, 26.05532, 28.84497, 29.77460, 32.56398, 37.21075, 36.28343, 37.21424, 41.86053, 44.64837, 47.44020, 48.36813, 51.15981, 52.08852};

double mass(int id) {
// return mass in GeV for the Corsika id secondary
    switch (id) {
    //1=foton, 2=e+, 3=e-, 5=mu+, 6=mu-, 7=pi0, 8=pi+, 9=pi-, 13=n, 14=p, 15=bar-p, other
        case 1:
            return (0.); //photon
            break;
        case 2:
        case 3:
            return (511.*kev2GeV);
            break;
        case 5:
        case 6:
            return (0.10566);
            break;
        case 7:
            return (0.13498);
            break;
        case 8:
        case 9:
            return (0.13957);
            break;
        case 13:
        case 25:
            return (0.93957);
            break;
        case 14:
        case 15:
            return (0.938272);
            break;
        default:
            if (id < 100)
                return 1.;
            else {
              int idm = 0;
              for (int i=0; i<masaN; i++)
                if (masaI[i] == id)
                    idm = i;
              return masas[idm];
            }
        return 1; // just in case
    }
}

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
  cout << endl << "primaries.cc, from ARTI     version " << VERSION << endl<< endl;
  cout << "  Read primary files and produce primary spectrum with and without geomagnetic field" << endl;
  cout << "  Usage: " << prog << " [flags] raw_file" << endl;
  cout << "    If 'raw_file' does not exits, switch to STDIN and use raw_file as" << endl;
  cout << "    basename for output file." << endl;
  cout << "    flags:"<<endl;
  cout << "      -m <n>          : Energy distribution of primaries per type, with <n> bins per decade."<<endl;
  cout << "      -n <a> <t>      : Normalize energy distribution in particles/(m2 s bin), <a>=detector area (m2), <t> = flux time (s)." <<endl;
  cout << "      -g <file> <col> : Include geomagentic effects. Read  rigidities from column <R> of <file>. Default R= " << cGeoCdef <<endl;
  cout << "                        3=R_U, 4=R_C 5=R_L"<<endl;
  cout << "      -v              : Enable verbose output (each -v increases verbosity level)"<< endl;
  cout << "      -?              : prints help and exits"<<endl << endl;
  if (iverbose) {
    // verbose help
  }
  exit(1);
}

inline double momentum(double px, double py, double pz) {
  return (GeV2keV*sqrt(px*px+py*py+pz*pz));
}

inline double energy(double m, double pkeV) {
// Energy in GeV for a particle of mass m and momentum m
  double p = pkeV * kev2GeV; // Asuming pkeV comes from momentum function (in keV)
  return (sqrt(m * m + p * p));
}

inline double log10(double x) {
  return (log(x)/log(10.));
}

int main (int argc, char *argv[]) {
  char nfi[256]; // filename container
  char nfg[256]; // geomagnetic effects file
  char *ifiname=NULL; // input
  char line[256];

  x = y = z = h = 0.;
  // reading arguments from command line
  for (int i=1;i<argc;i++) {
    char *tmparg=argv[i];
    if (*tmparg=='-') {
      switch (*(tmparg+1)) {
        case 'm':
          ianalysis=1;
          if (atof(argv[i+1])) {
            i++;
            resolution = atof(argv[i]);
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
        case 'v':
          iverbose++;
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
  snprintf(nfi,256,"bzip2 -9z > %s.prg.bz2",ifile);
  if ((pri = popen(nfi,"w"))==NULL) {
    fprintf(stderr,"Failed to open compressed output file. Abort.\n");
    exit(1);
  }
  if (ianalysis) {
    fprintf(stderr, "Sorry, it is not yet implemented.\n");
    ianalysis=false;
    /*
    snprintf(nfi, 256, "%s.pri.hst", ifile);
    if ((hst = fopen(nfi,"w"))==NULL) {
      fprintf(stderr,"Failed to open pri.hst (primary energy histogram) file. Abort.\n");
      exit(1);
    }
    */
  }
  fprintf(pri, "# # # prg\n");
  if (igeo)
    fprintf(pri, "# # Geomagnetic effects were included: %d values were read from column %d of file %s\n", iGeoN, cGeoC+1, nfg);
  fprintf(pri, "# # This is the Primaries file including geomagnetic effects - ARTI     %s\n", VERSION);
  fprintf(pri, "# # Include an extra column (#11) indicating geomagnetic status: \n");
  fprintf(pri, "# # 0: not-allowed // 1: allowed\n");
  fprintf(pri, "# # 11 column format is:\n");
  fprintf(pri, "# # prm_Crk_id prm_energy prm_x0 prm_theta prm_phi ph_obs_lev el_obs_lev hd_obs_lev mu_obs_lev tot_obs_lev geo_status\n");
  if (ianalysis) {
    fprintf(hst, "# # # hst\n");
    if (igeo)
      fprintf(hst, "# # Geomagnetic effects were included: %d values were read from file %s\n", iGeoN, nfg);
    fprintf(hst, "# # This is the Histogram of secondary energy file - ARTI     %s\n", VERSION);
    fprintf(hst, "# # Logaritmic energy scale. Resolution used: %d bins per energy decade\n", int(resolution));
    if (inorm)
      fprintf(hst, "# # Number of particles are divided by detector area (%.4f m^2) and flux time (%.2f s)\n", area, fluxTime);
    fprintf(hst, "# # 14 column format is:\n");
    fprintf(hst, "# # p_in_bin(GeV) N_phot N_e+ N_e- N_mu+ N_mu- N_pi0 N_pi+ N_pi- N_n N_p N_pbar N_others Total_per_bin\n");
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
  int nbin=12, nloge=0;
  int nlogd=0;
  nloge = int(log10(GeV2keV*maxPInGeV)*resolution);
  long int histoe[nloge][nbin];
  long int nid[nbin], nle[nloge];
  nlogd = int(log10(maxDInM)*resdist);
  long int histod[nlogd][nbin];
  long int nld[nlogd];
  double histode[nlogd][nbin];
  double nlde[nlogd];
  long int maxDerr = 0, maxEerr = 0;
  int prmId, prmX, prmZ, prmA;
  double prmEn, prmTh, prmPh;
  double prmMa, prmIm;
  double secp = 0.;
  bool prmGeo = true;
  int iprmGeo = 1;
  long int geoDisShw = 0, geoDisSec = 0;
  long int totpart=0, totbin = 0;
  int minbine=10000000, maxbine=0;
  int minbind=10000000, maxbind=0;
  for (int i=0; i<nbin; i++) {
    for (int j=0; j<nloge; j++) {
      histoe[j][i] = 0;
    }
    nid[i] = 0;
  }
  for (int j=0; j<nloge; j++)
    nle[j] = 0;

  long int lines = 0, ps = 0, shower_id = 0;
  while(fgets(line,250,fi)) {
    if (!(++lines % 10000))
      fprintf (stderr, "%12ld\r", lines);
    if (line[0] == '#') {  // comments? meta-data? for now, just skipping
      continue;
    }
    do { // read
      check=sscanf(line, "%lf %le %le %lf %lf %le %le %le %le %le\n", &d[0], &d[1], &d[2], &d[3], &d[4], &d[5], &d[6], &d[7], &d[8], &d[9]);
    } while (check != 10);
    if (d[0]<1)
      continue;

    //checking for geomagnetic effects
    if (igeo) {
      prmId=d[0];
      prmGeo=true;
      iprmGeo=1;
      if (prmId>1) { // only check for charged particles (photons=1)
        prmEn=d[1];
        prmTh=d[3];
        //CORSIKA System: -180 to +180 , 0=N, +90=E, counterclockwise
        //MAGCOS  System: 0 to 360 , 0=N, +90=E, clockwise.
        //Wonderful...
        //So... if CRK>=0, MAGCOS=CORSIKA...
        if (d[4] >= 0.)
          prmPh=d[4];
        //...else, MAGCOS=360+CORSIKA (CRK < 0)
        else
          prmPh=360.+d[4];
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
          iprmGeo = 0;
          geoDisShw++;
        }
      }
    }
    do {
      // fprintf(pri, "# # prm_Crk_id prm_energy prm_x0 prm_theta prm_phi ph_obs_lev el_obs_lev hd_obs_lev mu_obs_lev tot_obs_lev geo_status\n");
      check=fprintf(pri, "%04d %+.5E %+.5E %+08.3lf %+08.3lf %+.5E %+.5E %+.5E %+.5E %+.5E %d\n", prmId, prmEn, d[2], prmTh, d[4], d[5], d[6], d[7], d[8], d[9], iprmGeo);
    } while (check<=0);
    totpart++;
  }
  // say goodbye
  cerr << "From " << totpart << " primaries, in " << lines << " lines, " << geoDisShw << " primaries were discarded" << endl;
  fprintf(pri, "# # Total primaries: %ld, Discarded primaries: %ld, Allowed primaries: %ld\n", totpart, geoDisShw, (totpart-geoDisShw));
  pclose(pri);
}