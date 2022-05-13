// Geant4 Libraries
//
#include "G4VUserDetectorConstruction.hh"
#include "G4PVPlacement.hh"
#include "G4LogicalVolume.hh"
#include "G4ThreeVector.hh"
#include "G4Material.hh"
#include "G4Element.hh"
#include "G4LogicalVolume.hh"
#include "G4UnitsTable.hh"
#include "G4SystemOfUnits.hh" 
#include "G4OpticalSurface.hh"
#include "G4LogicalBorderSurface.hh"
#include "G4NistManager.hh"


// Local Libraries
//
#include "wcdLagoCont.hh"


wcdLagoCont::wcdLagoCont()
{
  G4cout << "...wcdLago..." << G4endl;

  // Initializing for mechanical detector
  //
  tank_geo = NULL;
  tank_log = NULL;
  tank_phys = NULL;

  wcdRad = 80*cm;
  wcdHig = 30*cm;

}


wcdLagoCont::~wcdLagoCont()
{}


void wcdLagoCont::DefineMaterials()
{
  G4NistManager* nist = G4NistManager::Instance();

  tank_steel 
    = nist->FindOrBuildMaterial("G4_STAINLESS-STEEL");
}

void wcdLagoCont::buildDetector(G4LogicalVolume* log_mother, G4bool* overLaps, G4double radius, G4double hight)
{
 tank_geo = 
    new G4Tubs("wcdTank",
        0.*cm,
        radius + .1*cm, //48.1*cm, //105.1*cm,
        hight/2 + .05*cm, //31.05*cm, //45.05*cm,
        0.*deg,
        360.*deg
        );


  tank_log = 
    new G4LogicalVolume(tank_geo,
      tank_steel,
      tank_geo->GetName(),
      0,
      0,
      0
      );


  tank_phys =
    new G4PVPlacement(0,
        G4ThreeVector(0.*cm, 0.*cm, 0.*cm),
        tank_log,
        tank_log->GetName(),
        log_mother,
        false,
        0,
        overLaps
        );
}


G4VPhysicalVolume* wcdLagoCont::getPhysVolume()
{
  return tank_phys;
}


G4LogicalVolume* wcdLagoCont::getLogVolume()
{
  return tank_log;
}
