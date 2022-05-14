#ifndef worldGround_h
#define worldGround_h 1


// Geant4 Libraries
//
#include "G4Material.hh"
#include "G4LogicalVolume.hh"
#include "G4PVPlacement.hh"
#include "G4Box.hh"
#include "G4SystemOfUnits.hh" 


// Local Libraries
//


class worldGround
{
  public:
    worldGround();
    virtual ~worldGround();

    void DefineMaterials();
    void buildDetector(G4LogicalVolume* log_mother, G4bool* overLaps);

    G4VPhysicalVolume* getPhysVolume();
    G4LogicalVolume* getLogVolume();

    G4double worldGround_size;

  private:

    G4Material* worldGround_matter;
    G4Box* worldGround_geo;
    G4LogicalVolume* worldGround_log;
    G4VPhysicalVolume* worldGround_phys;
};
#endif
