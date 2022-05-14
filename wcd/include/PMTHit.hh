#ifndef PMTHit_h
#define PMTHit_h 1


// Geant4 Libraries
//
#include "G4VHit.hh"
#include "G4THitsCollection.hh"
#include "G4Allocator.hh"
#include "G4ThreeVector.hh"
#include "G4LogicalVolume.hh"
#include "G4Transform3D.hh"
#include "G4RotationMatrix.hh"
#include "G4VPhysicalVolume.hh"

#include "tls.hh"


// Local Libraries
//


class G4VTouchable;


class PMTHit //: public G4VHit
{

  public:

    PMTHit();
    virtual ~PMTHit();
    G4int askDetected(G4double);
    void reset();

  private:
    G4double waveLength;
    double probaCollect = 0.7;
};
#endif
