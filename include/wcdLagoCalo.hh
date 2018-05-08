#ifndef wcdLagoCalo_h
#define wcdLagoCalo_h 1


// Geant4 Libraries
//
#include "G4Material.hh"
#include "G4LogicalVolume.hh"
#include "G4PVPlacement.hh"
#include "G4Tubs.hh"
#include "G4SystemOfUnits.hh" 


// Local Libraries
//


class wcdLagoCalo
{
  public:
    wcdLagoCalo();
    virtual ~wcdLagoCalo();

    void DefineMaterials();
    void buildDetector(G4LogicalVolume* log_mother, G4VPhysicalVolume* tank_phys, G4bool* overLaps, G4double radius, G4double hight);

    G4VPhysicalVolume* getPhysVolume();
    G4LogicalVolume* getLogVolume();

  private:
    G4Material* wcdWater;

    G4Tubs* water_geo;
    G4LogicalVolume* water_log;
    G4VPhysicalVolume* water_phys;
};
#endif
