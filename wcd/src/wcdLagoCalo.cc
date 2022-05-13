// Geant4 Libraries
//
#include "G4VUserDetectorConstruction.hh"
#include "G4PVPlacement.hh"
#include "G4LogicalVolume.hh"
#include "G4ThreeVector.hh"
#include "G4Material.hh"
#include "G4Element.hh"
#include "G4LogicalVolume.hh"
#include "G4Tubs.hh"
#include "G4UnitsTable.hh"
#include "G4SystemOfUnits.hh" 
#include "G4OpticalSurface.hh"
#include "G4LogicalBorderSurface.hh"
#include "G4NistManager.hh"


// Local Libraries
//
#include "wcdLagoCalo.hh"
#include "water.hh"


wcdLagoCalo::wcdLagoCalo()
{}


wcdLagoCalo::~wcdLagoCalo()
{}


void wcdLagoCalo::DefineMaterials()
{
  water* tmp = new water();
  wcdWater = tmp->doWater();
  wcdWater->SetMaterialPropertiesTable(tmp->doOpwater());
}


void wcdLagoCalo::buildDetector(G4LogicalVolume* log_mother, G4VPhysicalVolume* tank_phys, G4bool* overLaps, G4double radius, G4double hight)
{
  water_geo = 
    new G4Tubs("watervol",
        0.*cm, 	//inner radio
        radius, //48.*cm, //105.*cm, //outer radio
        hight/2, //31.*cm, //45.*cm,  //High 
        0.*deg, 	
        360.*deg);

  water_log = 
    new G4LogicalVolume(water_geo,
        wcdWater,
        water_geo->GetName(),
        0,
        0,
        0
        );

  water_phys =
    new G4PVPlacement(0,
        G4ThreeVector(0.*cm, 0.*cm, 0.*cm),
        water_log,
        water_log->GetName(),
        log_mother,
        false,
        0,
        overLaps
        );

  // ============================
  // *** Set Tyvek as coating ***
  G4OpticalSurface* opWaterSurface 
    = new G4OpticalSurface("OptTyvke");

  opWaterSurface->SetType(dielectric_LUT);
  opWaterSurface->SetFinish(groundtyvekair);
  opWaterSurface->SetModel(LUT);

  new G4LogicalBorderSurface (
      "WaterTyvekTank",
      water_phys,
      tank_phys,
      opWaterSurface
      );
}


G4VPhysicalVolume* wcdLagoCalo::getPhysVolume()
{
  return water_phys;
}


G4LogicalVolume* wcdLagoCalo::getLogVolume()
{
  return water_log;
}
