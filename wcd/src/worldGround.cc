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
#include "worldGround.hh"


worldGround::worldGround()
{}


worldGround::~worldGround()
{}


void worldGround::DefineMaterials()
{
  G4NistManager* nist = G4NistManager::Instance();

  worldGround_matter = nist->FindOrBuildMaterial("G4_AIR");
}


void worldGround::buildDetector(G4LogicalVolume* log_mother, G4bool* overLaps)
{
  worldGround_size = 50.*m;

  worldGround_geo =
    new G4Box("worldGround",
        worldGround_size,
        worldGround_size,
        worldGround_size
        );

  worldGround_log =
    new G4LogicalVolume(worldGround_geo,
      worldGround_matter,
      worldGround_geo->GetName(),
      0,
      0,
      0
      );

  worldGround_phys =
    new G4PVPlacement(0,
      G4ThreeVector(0.*m, 0.*m, 0.*m),
      worldGround_log,
      worldGround_log->GetName(),
      log_mother,
      false,
      0,
      overLaps
      );
}


G4VPhysicalVolume* worldGround::getPhysVolume()
{
  return worldGround_phys;
}


G4LogicalVolume* worldGround::getLogVolume()
{
  return worldGround_log;
}
