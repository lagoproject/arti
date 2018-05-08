
// Geant4 Libraries
//
#include "G4Material.hh"
#include "G4Element.hh"

#include "G4LogicalBorderSurface.hh"
#include "G4LogicalSkinSurface.hh"
#include "G4OpticalSurface.hh"
#include "G4MultiFunctionalDetector.hh"
#include "G4VPrimitiveScorer.hh"
#include "G4PSEnergyDeposit.hh"
#include "G4VPhysicalVolume.hh"

#include "G4Box.hh"
#include "G4Sphere.hh"
#include "G4LogicalVolume.hh"
#include "G4ThreeVector.hh"
#include "G4PVPlacement.hh"
#include "G4SystemOfUnits.hh"
#include "G4NistManager.hh"
#include "G4UnitsTable.hh"
#include "G4PhysicalConstants.hh"


// Local Libraries
//
//#include "PMTSD.hh"
#include "DetectorConstruction.hh"
#include "PMTSD.hh"
#include "world.hh"
#include "wcdLagoCont.hh"
#include "wcdLagoCalo.hh"
#include "wcdpmt.hh"
#include "worldGround.hh"

// C++ Libraries
//


DetectorConstruction::DetectorConstruction()
 : G4VUserDetectorConstruction()
{
  G4cout << "...DetectorConstruction..." << G4endl;

  expHall = new world();
  groundBase = new worldGround();

  wcdCont = new wcdLagoCont(); 
  wcdCalo = new wcdLagoCalo(); 
  pmt_det = new wcdpmt(); 
}


DetectorConstruction::~DetectorConstruction()
{}

// *************************
// Doing Mechanical Detector
// ************************* 

G4VPhysicalVolume* DetectorConstruction::Construct()
{                        
  G4bool checkOverlaps = true;

  expHall->DefineMaterials();
  expHall->buildDetector(&checkOverlaps);

  groundBase->DefineMaterials();
  groundBase->buildDetector(expHall->getLogVolume(), &checkOverlaps);

  G4double wcdRadius = 48.*cm;
  G4double wcdHight = 62.*cm;

  wcdCont->DefineMaterials();
  wcdCont->buildDetector(groundBase->getLogVolume(), &checkOverlaps, wcdRadius, wcdHight);

  wcdCalo->DefineMaterials();
  wcdCalo->buildDetector(wcdCont->getLogVolume(), wcdCont->getPhysVolume(), &checkOverlaps, wcdRadius, wcdHight);

  pmt_det->DefineMaterials();
  pmt_det->buildDetector(wcdCalo->getLogVolume(), &checkOverlaps);
 
  fwaterVolume = wcdCalo->getPhysVolume();

  return expHall->getPhysVolume();
}
