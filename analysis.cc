/************************************************************************/
/*                                                                      */
/* Package:  CrkTools                                                   */
/* Module:   analysis.cc                                                */
/*                                                                      */
/************************************************************************/
/* Authors:  Hernán Asorey                                              */
/* e-mail:   asoreyh@cab.cnea.gov.ar                                    */
/*                                                                      */
/************************************************************************/
/* Comments: Main analysis program. Analize shower binary files and     */
/*           produce secondary files                                    */
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
const int block_size = 273;
const int block_rows = 39;
const int block_cols = 7;
const int read_tries = 10;
double data_block[block_size];
double run_header[block_size]; 
double evt_header[block_size]; 
double evt_footer[block_size]; 
double run_footer[block_size]; 
double evt_buffer[5] = {0.,0.,0.,0.,0.};

long int lines = 0, shower_id = 0, counter = 0;

int bad_block  = 0;
double chk_block[5] = {0.00000e+00, 1.11111e+07, 3.33333e+07, 7.77778e+07, 1.00000e+08};
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

int ReadBlock(double *block, int type) {
  int read_line_error = 0, check = 0, read_no_error=1;
  bad_block=0;
  for (int row=0; row<block_rows; row++) {
    if (fgets(line,250,fi)!=NULL) {
      do {
        check=sscanf(
          line, "%le %le %le %le %le %le %le\n", 
          &block[block_cols * row + 0], 
          &block[block_cols * row + 1], 
          &block[block_cols * row + 2], 
          &block[block_cols * row + 3], 
          &block[block_cols * row + 4], 
          &block[block_cols * row + 5], 
          &block[block_cols * row + 6]
        );
      } while (check != block_cols && read_line_error++ < read_tries);
      lines++;
      if (read_line_error) {
        cerr << "Error: Bad block (missing elements) at block "<< type << ", row " << row+1 << endl;
        read_no_error=0;
        break;
      }
    }
    else { 
      cerr << "Error: EOF while reading block " << type << " at line " << row+1 << endl;
      read_no_error=0;
      break;
    }
  }
  if (block[0] != chk_block[type]) {
    // if we read the last event, then while we are trying to read the next event header we are actually reading the run_footer, so...
    if (type == 2 && block[0] == chk_block[4]) {
      events=false;
      for (int i=0; i<block_size; i++) 
        run_footer[i] = block[i];
    }
    else {  
      bad_block = 1;
      fprintf(stderr, "Error: Bad block error (unformated) at block %d. First element should be %.5E, and it is %.5E\n", type, chk_block[type], block[0]);
    }
  }
  return read_no_error;
}

int ReadDataBlock(double *block, int blk) {
  int read_line_error = 0, check = 0, read_no_error=1;
  for (int row=0; row<block_rows; row++) {
    if (fgets(line,250,fi)!=NULL) {
      do {
        check=sscanf(
          line, "%le %le %le %le %le %le %le\n", 
          &block[block_cols * row + 0], 
          &block[block_cols * row + 1], 
          &block[block_cols * row + 2],
          &block[block_cols * row + 3], 
          &block[block_cols * row + 4], 
          &block[block_cols * row + 5], 
          &block[block_cols * row + 6]
        );
      } while (check != block_cols && read_line_error++ < read_tries);
      lines++;
      if (read_line_error) {
        cerr << "Error: Bad data block (missing elements) at data block "<< blk << ", row " << (blk-1)*block_rows+row+1 << endl;
        read_no_error=0;
        break;
      }
    }
    else {
      cerr << "Error: EOF while reading data block " << blk << " at row " << (blk-1)*block_rows+row+1 << endl;
      read_no_error=0;
      break;
    }
    //one more check: if the first element of DataBlock is 7.77778E+07, then there is no secondaries, and we read evt_footer!
    if (block[0] == chk_block[3]) {
      data=false;
      for (int i=0; i<block_size; i++) 
        evt_footer[i] = block[i];
    }
  }
  return read_no_error;
}

inline double rad2deg (double rad) {
  return rad*180./M_PI; 
}

inline double deg2rad (double deg) {
  return deg*M_PI/180.;
}

void Usage(char *prog, int verbose=0) {
  cout << endl << "analysis.cc, from CrkTools version " << VERSION << endl<< endl;
  cout << "  Read ascii files containing Corsika Outputs and produce different files" << endl; 
  cout << "  containing secondaries, injection spectra, etc, acoording to options" << endl; 
  cout << "  selected by user." << endl; 
  cout << "  Usage: " << prog << " [flags] raw_file" << endl;
  cout << "    If 'raw_file' does not exits, switch to STDIN and use raw_file as" << endl;
  cout << "    basename for output file." << endl;
  cout << "    flags:"<<endl;
  cout << "      -p: create a separate file with information from all primaries"<<endl; 
  cout << "      -i: include headers and footers as comments in secondaries file"<<endl;
  cout << "      -d: debug mode: print headers and footers in stdout. Handle with care. *"<<endl;
  cout << "      -v: enable verbose outputs"<<endl; 
  cout << "      -f: force analysis (overide file sanity checks and continue. Handle with care)"<<endl; 
  cout << "      -?: prints help and exits"<<endl << endl;
  cout << "    * STILL NOT IMPLEMENTED"<<endl;
  if (verbose) {
    // verbose help
  }
  exit(1);
}

int main(int argc, char *argv[]) {

  char nfi[256]; // filename container
  char *ifiname=NULL; // input
  int block=0;

  // reading arguments from command line
  for (int i=1;i<argc;i++) {
    char *tmparg=argv[i];
    if (*tmparg=='-') {
      switch (*(tmparg+1)) {
        case 'v':
          iverbose=1;
          break;
        case 'p':
          iprim=1;
          break;
        case 'f':
          iforce=1;
          break;
        case 'd':
          idegub=1;
          break;
        case 'i':
          iinclude=1;
          break;
        case '?':
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
  //secondaries
  snprintf(nfi,256,"bzip2 -9z > %s.sec.bz2",ifile);
  if ((sec = popen(nfi,"w"))==NULL) {
    fprintf(stderr,"Failed to open compressed secondaries file. Abort.\n");
    exit(1);
  }
  fprintf(sec, "# # # sec\n");
  fprintf(sec, "# # This is the Secondaries file - CrkTools %s\n", VERSION);
  fprintf(sec, "# # 12 column format is:\n");
  fprintf(sec, "# # CorsikaId px py pz x y t shower_id prm_id prm_energy prm_theta prm_phi\n");
  if (iforce)
    cerr << "WARNING! Force mode is enabled. Consistency checks will be ignorated\n";
  //primaries
  if (iprim) {
    snprintf(nfi,256,"bzip2 -9z > %s.pri.bz2",ifile);
    if ((pri = popen(nfi,"w"))==NULL) {
      fprintf(stderr,"Failed to open compressed primaries file. Abort.\n");
      exit(1);
    }
    fprintf(pri, "# # # pri\n");
    fprintf(pri, "# # This is the Primaries file - CrkTools %s\n", VERSION);
    fprintf(pri, "# # 10 column format is:\n");
    fprintf(pri, "# # prm_Crk_id prm_energy prm_x0 prm_theta prm_phi ph_obs_lev el_obs_lev hd_obs_lev mu_obs_lev tot_obs_lev\n");
  }

  if (iforce)
    cerr << "WARNING! Force mode is enabled. Consistency checks will be ignorated\n";

  // stop talking, let's work

  for (int i=0; i<block_size; i++)
    data_block[i] = run_header[i] = evt_header[i] = evt_footer[i] = run_footer[i] = 0.;

  // Reading RUN HEADER (273=7x39)
  if (iverbose)
    cerr << "Files opened. Reading run header" << endl;
  if (!ReadBlock(run_header, 1) || bad_block)
    if (!iforce)
      exit(1);
  if (iinclude) {
    fprintf(sec, "# r");
    for (int i=0; i<block_size; i++)
      fprintf(sec, " %+.5E", run_header[i]);
    fprintf(sec, "\n");
  } 
  // Everything ok, continue
  // events
  // event header
  events=true;
  while (events) {
    if (!ReadBlock(evt_header, 2) || bad_block)
      if (!iforce)
        exit(1);
    if (!events)
      break;
    //reading data blocks for this events
    shower_id++;
    if (iverbose)
      cerr << "Reading event " << shower_id << endl;
    block = 1;
    data=true;
    if (iinclude) {
      fprintf(sec, "# h");
      for (int i=0; i<block_size; i++)
        fprintf(sec, " %+.5E", evt_header[i]);
      fprintf(sec, "\n");
    }
     
    if (iprim) {
      evt_buffer[0] = evt_header[2];
      evt_buffer[1] = evt_header[3];
      evt_buffer[2] = evt_header[6]/1e5;
      evt_buffer[3] = rad2deg(evt_header[10]);
      evt_buffer[4] = rad2deg(evt_header[11]);
    }
    while (data) {
      if (!ReadDataBlock(data_block, block))
        if (!iforce)
          exit(1);
      if (!data)
        break;
      for (int i=0; i<block_rows; i++) {
      if (iverbose)
        fprintf(stderr, "Reading block: %08d\r", block);
        if (data_block[i*block_cols]) {
          if (data_block[i*block_cols]>0) {
            fprintf (
              sec, "%04d %+.5E %+.5E %+.5E %+.5E %+.5E %+.5E %08ld %04d %+.5E %+07.3lf %+08.3lf\n",
              int(data_block[i*block_cols+0]/1000.),
              data_block[i*block_cols+1], 
              data_block[i*block_cols+2], 
              data_block[i*block_cols+3], 
              data_block[i*block_cols+4], 
              data_block[i*block_cols+5], 
              data_block[i*block_cols+6],
              shower_id,
              int(evt_header[2]),
              evt_header[3],
              rad2deg(evt_header[10]),
              rad2deg(evt_header[11])
            ); 
            fflush(sec);
            counter++;
          }
        }
        else { // no more particles
          if (iverbose)
            fprintf(stderr,"\nNo more particles for this event.\n");
          data=false;
          break;
        }
      }
      block++;
    }
    if (!evt_footer[0])
      if (!ReadBlock(evt_footer, 3) || bad_block)
        if (!iforce)
          exit(1);
    if (iinclude) {
      fprintf(sec, "# f");
      for (int i=0; i<block_size; i++)
        fprintf(sec, " %+.5E", evt_footer[i]);
      fprintf(sec, "\n");
    } 
    if (iprim) {
      fprintf (
        pri, "%04d %+.5E %+.5E %+08.3lf %+08.3lf %+.5E %+.5E %+.5E %+.5E %+.5E\n",
        int(evt_buffer[0]),
        evt_buffer[1],
        evt_buffer[2],
        evt_buffer[3],
        evt_buffer[4],
        evt_footer[2],
        evt_footer[3],
        evt_footer[4],
        evt_footer[5],
        evt_footer[6]
      );
      for (int i=0; i<block_size; i++)
        evt_footer[i] = 0.;
    }
    else
      evt_footer[0] = 0.; // force lecture of the new event footer
  }
  fprintf(sec, "# # %ld lines read on %ld secondaries for %ld showers\n", lines, counter, shower_id);
  fprintf(stderr, "%ld lines read on %ld secondaries for %ld showers\nEverything fine. Goodbye\n\n", lines, counter, shower_id);
  pclose(sec);
}

/* should be included in LONG analysis version TODO
    fprintf(pri, "# # 17 column format is:\n");
    fprintf(pri, "# # prm_Crk_id prm_energy prm_x0 prm_theta prm_phi ph_obs_lev el_obs_lev hd_obs_lev mu_obs_lev tot_obs_lev 11-16:param_long_dist_fit chi2_long_fit\n");
      fprintf (
        pri, "%04d %+.5E %+.5E %+08.3lf %+08.3lf %+.5E %+.5E %+.5E %+.5E %+.5E %+.5E %+.5E %+.5E %+.5E %+.5E %+.5E %+.5E\n",
        int(evt_header[2]),
        evt_header[3],
        evt_header[6]/1e5,
        rad2deg(evt_header[10]),
        rad2deg(evt_header[11]),
        evt_footer[2],
        evt_footer[3],
        evt_footer[4],
        evt_footer[5],
        evt_footer[6],
        evt_footer[255],
        evt_footer[256],
        evt_footer[257],
        evt_footer[258],
        evt_footer[259],
        evt_footer[260],
        evt_footer[261]
      );
*/
