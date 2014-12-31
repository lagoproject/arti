/************************************************************************/
/*                                                                      */
/* Package:  CrkTools                                                   */
/* Module:   cherenkov.cc                                               */
/*                                                                      */
/************************************************************************/
/* Authors:  Hernán Asorey                                              */
/* e-mail:   asoreyh@cab.cnea.gov.ar                                    */
/*                                                                      */
/************************************************************************/
/* Comments: Histogramize cherenkov photons distributions at detector   */
/*           level                                                      */
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
#include <iomanip>

using namespace std;

//global
FILE *fi, *sec, *pri;
const int block_cols = 7;
const int read_tries = 10;

long int lines = 0, hit_cter = 0;
long double pht_cter = 0.;

int bad_block  = 0;
bool events = true, data = true;

int iverbose = 0, iprim = 0, idegub = 0, iinclude = 0, iforce = 0;


char line[256];

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

void Usage(char *prog, int verbose=0) {
  cout << endl << "analysis.cc, from CrkTools version " << VERSION << endl<< endl;
  cout << "  Read ascii files containing Corsika Cherenkov outputs (CER) and produce a histogram" << endl; 
  cout << "  of photon density as a function of distance to core." << endl; 
  cout << "  Usage: " << prog << " [flags] raw_file" << endl;
  cout << "    If 'raw_file' does not exits, switch to STDIN and use raw_file as" << endl;
  cout << "    basename for output file." << endl;
  cout << "    flags:"<<endl;
  cout << "      -c <CERARY input line> : CERARY line (expects complete line!) from input file" << endl;
  cout << "      -v: enable verbose outputs"<<endl; 
  cout << "      -h: prints help and exits"<<endl << endl;
//  cout << "    * STILL NOT IMPLEMENTED"<<endl;
  if (verbose) {
    // verbose help
  }
  exit(1);
}

int iline=0, i2d=0;
int nx=0, ny=0;
double dx=0.,dy=0.;
double rx=0.,ry=0.;
double xOff = 0., xMirrOff=0.;
double yOff = 0., yMirrOff=0.;
const double cmtom = 0.01;

inline int getXbin(double x) {
// we have an array of nx mirrors centered at 0 and separated by dx m in the x direction
// if nx is odd, then our mirrors are located in i*nx, i=-(nx-1)/2...(nx-1)/2
  return (int((x+xOff+xMirrOff)/dx));
}

inline int getYbin(double y) {
// we have an array of nx mirrors centered at 0 and separated by dy m in the y direction
// if ny is odd, then our mirrors are located in j*ny, j=-(ny-1)/2...(ny-1)/2
  return (int((y+yOff+yMirrOff)/dy));
}

inline double getXpos(int i) {
  return ((i * dx - xOff)*cmtom);
}

inline double getYpos(int j) {
  return ((j * dy - yOff)*cmtom);
}

int main(int argc, char *argv[]) {

  char nfi[256]; // filename container
  char *ifiname=NULL; // input
  // reading arguments from command line
  for (int i=1;i<argc;i++) {
    char *tmparg=argv[i];
    if (*tmparg=='-') {
      switch (*(tmparg+1)) {
        case 'v':
          iverbose=1;
          break;
        case 'c':
          iline=1;
          i++; // discard "CERARY"
          nx=atoi(argv[++i]);
          ny=atoi(argv[++i]);
          dx=atof(argv[++i]);
          dy=atof(argv[++i]);
          rx=atof(argv[++i]);
          ry=atof(argv[++i]);
          break;
        case 'h':
        default:
          Usage(argv[0]);
          break;
      }
    }
    else {
      ifiname=argv[i];
    }
  }
  if (!ifiname) {
    cerr << endl << "Error: Missing filename" << endl << endl;
    Usage(argv[0]);
  }
  if (!iline) {
    cerr << endl << "Error: CERARY line is mandatory" << endl << endl;
    Usage(argv[0]);
  }

  // determine primary offsets...
  const double ext_mirr=2.; // some photons laid outside the mirror... bug in corsika? Asume 10% to avoid problems... Actually if should be lower than min(Dx/Rx,Dy/Ry)
  if (iverbose)
    cerr << "Array characteristics: " << endl << "Nx= " << nx << "; Ny= " << ny << "; Dx= "<< dx*cmtom << " m; Dy= "<< dy*cmtom << " m; Rx= "<< rx*cmtom << " m; Ry= "<< ry*cmtom << " m" << endl;
  if (ny>1) // one row is not 2d :P
    i2d=1;
  else // just in case ny=0
    ny=1;
  xMirrOff = rx/2. * ext_mirr;
  if (nx%2)
    xOff = dx * (nx - 1.) / 2.;
  else
    xOff = dx * nx  / 2.;

  yMirrOff = ry/2. * ext_mirr;
  if (ny%2)
    yOff = dy * (ny - 1.) / 2.;
  else
    yOff = dy * ny  / 2.;
  if (!dy)
    dy = 1.; // just to avoid problems 


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

  // open output file (.hst) via fopen
  //secondaries
  snprintf(nfi,256,"%s.hst",ifile);
  if ((sec = fopen(nfi,"w"))==NULL) {
    fprintf(stderr,"Failed to open histogram file. Abort.\n");
    exit(1);
  }
  fprintf(sec, "# # # hst\n");
  fprintf(sec, "# # This is the histogram of radial distribution of cherenkov phontons - CrkTools %s\n", VERSION);
  fprintf(sec, "# # Array characteristics: Nx= %d columns; Ny= %d rows; Dx= %.3f m; Dy= %.3f m; Rx= %.3f m; Ry= %.3f m\n", nx, ny, dx*cmtom, dy*cmtom, rx*cmtom, ry*cmtom);
  fprintf(sec, "# # 4 column format is:\n");
  fprintf(sec, "# # x y photons hits\n");

  // stop talking, let's work
  // histograms...
  double data[block_cols];
  int read_line_error = 0, check = 0;
  for (int k=0; k<block_cols; k++)
    data[k] = 0.;
  long double photons[nx][ny];
  long int hits[nx][ny];
  long int badx=0, bady=0;
  int i=0, j=0;
  for (i=0; i<nx; i++) {
    for (j=0; j<ny; j++) {
      photons[i][j]=0.;
      hits[i][j]=0;
    }
  }
  if (iverbose)
    cerr << "Files opened. Reading cherenkov data blocks" << endl;
  while (fgets(line,250,fi)!=NULL) {
    read_line_error=0;
    do {
      check=sscanf(line, "%le %le %le %le %le %le %le\n", &data[0], &data[1], &data[2], &data[3], &data[4], &data[5], &data[6]);
    } while (check != block_cols && read_line_error++ < read_tries);
    lines++;
    if (iverbose)
      if (!(lines%100000))
        fprintf(stderr, "%ld lines processed up to now\r", lines);
    if (data[0]>0) {
      i=getXbin(data[1]);
      if (i>nx) {
        if (iverbose)
          fprintf(stderr, "\nWarning: skipping photon hitting outside the array (index %d) at line %ld (%s)\n",i,lines,ifile);
        badx++;
        continue;
      }
      j=getYbin(data[2]);
      if (j>ny) {
        if (iverbose)
          fprintf(stderr, "\nWarning: skipping photon hitting outside the array (index %d) at line %ld (%s)\n",j,lines,ifile);
        bady++;
        continue;
      }
      photons[i][j] += data[0];
      hits[i][j]++;
      pht_cter+=data[0];
      hit_cter++;
    }
  }
  if (iverbose)
    fprintf(stderr,"\nDone... printing histograms...\n");
  for (int j=0;j<ny;j++) {
    for (i=0;i<nx;i++) {
      fprintf (sec, "%.3lf %.3lf %Lf %ld\n", getXpos(i), getYpos(j), photons[i][j], hits[i][j]);
    }
    fprintf (sec,"\n");
  }
  fprintf (sec, "# In %ld lines, we found %ld hits corresponding to %Lf photons, and %ld photons laid outside the array(x=%ld, y=%ld)\n", lines, hit_cter, pht_cter,badx+bady,badx,bady);
  fclose(sec);
}
