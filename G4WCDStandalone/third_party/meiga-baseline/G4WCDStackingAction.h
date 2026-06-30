#ifndef G4WCDStackingAction_h
#define G4WCDStackingAction_h 1

#include "Event.h"

#include <G4UserStackingAction.hh>
#include <G4ClassificationOfNewTrack.hh>
#include <G4Track.hh>



class G4Track;


class G4WCDStackingAction : public G4UserStackingAction {

/*

    basic Geant4 stacking action class.

    this class is intended to speed-up the
    WCD simulation by killing Cerenkov photons according
    to their energy and the PMT quantum efficiency
    

  */

public:

  G4WCDStackingAction(Event& theEvent);
  virtual ~G4WCDStackingAction();

  G4ClassificationOfNewTrack ClassifyNewTrack(const G4Track* const track) override;

private:
  Event& fEvent;

};

#endif