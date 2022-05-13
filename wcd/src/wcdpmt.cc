// Geant4 Libraries
//
#include "G4PVPlacement.hh"
#include "G4LogicalVolume.hh"
#include "G4ThreeVector.hh"
#include "G4Material.hh"
#include "G4LogicalVolume.hh"
#include "G4UnitsTable.hh"
#include "G4SystemOfUnits.hh" 
#include "G4NistManager.hh"


// Local Libraries
//
#include "wcdpmt.hh"


wcdpmt::wcdpmt()
{
  G4cout << "...pmt..." << G4endl;

  // Initializing for mechanical detector
  //
  pmt_geo = NULL;
  pmt_log = NULL;
  pmt_phy = NULL;
}


wcdpmt::~wcdpmt()
{}


void wcdpmt::DefineMaterials()
{
  G4NistManager* nist = G4NistManager::Instance();

  pmt_mat
    = nist->FindOrBuildMaterial("G4_AIR");
}

void wcdpmt::buildDetector(G4LogicalVolume* log_mother, G4double postZ, G4bool* overLaps)
{
  G4double pxSemiAxis = 10.1*cm;
  G4double pySemiAxis = 10.1*cm;
  G4double pzSemiAxis = 6.5*cm;
  G4double pzBottomCut = -pzSemiAxis;
  G4double pzTopCut = 0.*cm;

  pmt_geo
    = new G4Ellipsoid("pmt_geo",
    pxSemiAxis,
    pySemiAxis,
    pzSemiAxis,
    pzBottomCut,
    pzTopCut
    );

  pmt_log
    = new G4LogicalVolume(pmt_geo,
        pmt_mat,
        pmt_geo->GetName()
        );

  pmt_phy
    =  new G4PVPlacement(0,
      G4ThreeVector (0.*cm, 0.*cm, postZ/2.), //60.*cm),//45.*cm),//80.*cm),//295.*cm),//60.*cm),
      pmt_log,
      pmt_log->GetName(),
      log_mother,
      false,
      0,
      overLaps
      );
}


G4VPhysicalVolume* wcdpmt::getPhysVolume()
{
  return pmt_phy;
}

G4LogicalVolume* wcdpmt::getLogVolume()
{
  return pmt_log;
}
