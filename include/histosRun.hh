#ifndef histosRun_h
#define histosRun_h 1


// Geant4 Libraries
//


// Root Libraries
//
class TFile;
class TTree;
class TH1F;
class TH1I;
class TH2D;


// Local Libraries
//
#include "histosMessenger.hh"


class histosRun
{
  public:
    histosRun();
    ~histosRun();

    // ===========================
    // *** Initializing histos ***
    void initHistos();

    // ===================
    // *** For photons ***
    void cerenPho(int optCerenPho);
    void fillCerenPho(int optFillPho);

    void cerenPhoPmt(int optCerenPhoPmt);
    void fillCerenPhoPmt(int optFillPhoPmt);

    void cerenPhoElect(int optCerenPhoElect);
    void fillCerenPhoElect(int optCerenPhoElect); 

    // ==============
    // *** Pulses ***
    void meanPulse(int optMeanPulse, double time);

    // =======================
    // *** inside detector ***
    void trackLengthDetec(int optLengthDectec, double length);
    void fillTrackLengthDetec(int optFillLengthDectec);

    // ================
    // *** Injected ***
    void distInject(int part);
    void postInject(double partPosX, double partPosY);

    void setOutFileName(G4String name);



  private:

    // ===================
    // *** Output File ***
    histosMessenger* histoRunMess;
    TFile* histosOutput;

    // ===================
    // *** For photons ***
    TH1F* histCerenPhoMuon;
    TH1F* histCerenPhoElec;
    TH1F* histCerenPhoGamm;
    TH1F* histCerenPhoNeut;
    TH1F* histCerenPhoHadr;
    TH1F* histCerenPhoAll;
    int cMuonCerPho;
    int cElecCerPho;
    int cGammCerPho;
    int cNeutCerPho;
    int cHadrCerPho;
    int cAllCerPho;

    TH1F* histCerenPhoPmtMuon;
    TH1F* histCerenPhoPmtElec;
    TH1F* histCerenPhoPmtGamm;
    TH1F* histCerenPhoPmtNeut;
    TH1F* histCerenPhoPmtHadr;
    TH1F* histCerenPhoPmtAll;
    int cMuonPhoPmt;
    int cElecPhoPmt;
    int cGammPhoPmt;
    int cNeutPhoPmt;
    int cHadrPhoPmt;
    int cAllPhoPmt;

    TH1F* histCerenPhoElectMuon;
    TH1F* histCerenPhoElectElec;
    TH1F* histCerenPhoElectGamm;
    TH1F* histCerenPhoElectNeut;
    TH1F* histCerenPhoElectHadr;
    TH1F* histCerenPhoElectAll;
    int cMuonPhoElect;
    int cElecPhoElect;
    int cGammPhoElect;
    int cNeutPhoElect;
    int cHadrPhoElect;
    int cAllPhoElect;


    // ==================
    // *** For pulses ***
    TH1F* histMeanPulseMuon;
    TH1F* histMeanPulseElec;
    TH1F* histMeanPulseGamm;
    TH1F* histMeanPulseNeut;
    TH1F* histMeanPulseHadr;
    TH1F* histMeanPulseAll;


    // =======================
    // *** inside detector ***
    TH1F* histTrackLengthDetecMuon;
    TH1F* histTrackLengthDetecElec;
    TH1F* histTrackLengthDetecGamm;
    TH1F* histTrackLengthDetecNeut;
    TH1F* histTrackLengthDetecHadr;
    TH1F* histTrackLengthDetecAll;
    double cMuonLengthDetec;
    double cElecLengthDetec;
    double cGammLengthDetec;
    double cNeutLengthDetec;
    double cHadrLengthDetec;
    double cAllLengthDetec;

    const double mm2cm = 10.;


    // ================
    // *** Injected ***
    TH1I* histPartInject;
    TH2D* histPostInject;
};
#endif
