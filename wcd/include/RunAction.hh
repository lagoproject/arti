#ifndef RunAction_h 
#define RunAction_h 1


// Geant4 Libraries
//
#include "globals.hh"
#include "G4UserRunAction.hh"
#include "g4root.hh"


// Local Libraries
//
#include "histosRun.hh"


class G4Timer;
class G4Run;


class RunAction : public G4UserRunAction
{
  public:
    RunAction();
    virtual ~RunAction();

  public:
    virtual void BeginOfRunAction(const G4Run* aRun);
    virtual void EndOfRunAction(const G4Run* aRun);

    histosRun* histRun;

  private:
    G4AnalysisManager* analysisManager = G4AnalysisManager::Instance();
    G4Timer* fTimer;

    int histRunOk = 1;
};
#endif /*RunAction_h*/
