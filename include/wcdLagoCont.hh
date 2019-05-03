#ifndef wcdLagoCont_h
#define wcdLagoCont_h 1


// Geant4 Libraries
//
#include "G4Material.hh"
#include "G4LogicalVolume.hh"
#include "G4PVPlacement.hh"
#include "G4Tubs.hh"
#include "G4SystemOfUnits.hh" 


// Local Libraries
//


class wcdLagoCont 
{
  public:
    wcdLagoCont();
    virtual ~wcdLagoCont();

    void DefineMaterials();
    void buildDetector(G4LogicalVolume* log_mother, G4bool* overLaps, G4double radius, G4double hight);

    G4VPhysicalVolume* getPhysVolume();
    G4LogicalVolume* getLogVolume();


  private:

    G4Material* tank_steel;
    
    G4Tubs* tank_geo;
    G4LogicalVolume* tank_log;
    G4VPhysicalVolume* tank_phys;

    G4double wcdRad;
    G4double wcdHig;
};
#endif

