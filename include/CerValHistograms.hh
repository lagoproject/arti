#ifndef CerValHistograms_h
#define CerValHistograms_h 1


class TFile;
class TTree;
class TH1F;


class CerValHistograms
{
  public:
    CerValHistograms();
    virtual ~CerValHistograms();
    void doHistCerPhoCm(G4double nphoVcm);
    void creatingHist(G4int runId);
    void resetHist();

    void creatHistStopPow(G4int runId);

  private:
    TFile* rfCerValHist;
    TTree* testTree;

    TH1F* histPhoVcm;
};
#endif
