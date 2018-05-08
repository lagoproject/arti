#ifndef world_h
#define world_h 1


// Geant4 Libraries
//
#include "G4Material.hh"
#include "G4LogicalVolume.hh"
#include "G4PVPlacement.hh"
#include "G4Box.hh"


// Local Libraries
//


class world 
{
  public:
    world();
    virtual ~world();
    void DefineMaterials();
    void buildDetector(G4bool* overLaps);
    G4LogicalVolume* getLogVolume();
    G4VPhysicalVolume* getPhysVolume();

  private:
    G4Material* expHall_mat;

    G4Box* expHall_geo;
    G4LogicalVolume* expHall_log;
    G4VPhysicalVolume* expHall_phys;
};
#endif

