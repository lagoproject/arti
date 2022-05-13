// Geant4 Libraries
//
#include "G4PVPlacement.hh"
#include "G4LogicalVolume.hh"
#include "G4ThreeVector.hh"
#include "G4Material.hh"
#include "G4LogicalVolume.hh"
#include "G4Box.hh"
#include "G4UnitsTable.hh"
#include "G4SystemOfUnits.hh" 
#include "G4NistManager.hh"


// Local Libraries
//
#include "world.hh"

world::world()
{
  G4cout << "...world..." << G4endl;

  // Initializing for mechanical detector
  //
  expHall_geo = NULL;
  expHall_log = NULL;
  expHall_phys = NULL;
}


world::~world()
{}


void world::DefineMaterials()
{
  G4NistManager* nist = G4NistManager::Instance();

  expHall_mat
    = nist->FindOrBuildMaterial("G4_AIR");
}

void world::buildDetector(G4bool* overLaps)
{
  G4double dimenWorld = 200.*m;
  expHall_geo = 
    new G4Box("expHall_geo",
        dimenWorld,
        dimenWorld,
        dimenWorld
        );
  
  expHall_log = 
    new G4LogicalVolume(expHall_geo,
       expHall_mat,
      "expHall_log",
      0,
      0,
      0
      );

  expHall_phys =
    new G4PVPlacement(0,
        G4ThreeVector(0.*cm, 0.*cm, 0.*cm),
        expHall_log,
        "expHall",
        0,
        false,
        0,
        overLaps
        );
}


G4LogicalVolume* world::getLogVolume()
{
  return expHall_log;
}


G4VPhysicalVolume* world::getPhysVolume()
{
  return expHall_phys;
}
