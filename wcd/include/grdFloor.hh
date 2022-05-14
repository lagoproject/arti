#ifndef grdFloor_h
#define grdFloor_h 1


// Geant4 Libraries
//
#include "G4Element.hh"
#include "G4LogicalVolume.hh"
#include "G4PVPlacement.hh"
#include "G4Box.hh"
#include "G4SystemOfUnits.hh" 


// Local Libraries
//


class grdFloor
{
  public:
    grdFloor();
    ~grdFloor();

    void DefineMaterials();
    void buildDetector(G4double grd_size, G4LogicalVolume* log_mother, G4bool* overLaps);

    G4VPhysicalVolume* getPhysVolume();
    G4LogicalVolume* getLogVolume();


  private:
    G4Material* grdFloor_mat;

    G4Box* grdFloor_geo;
    G4LogicalVolume* grdFloor_log;
    G4VPhysicalVolume* grdFloor_phys;
};
#endif
