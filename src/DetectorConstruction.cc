
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

#include "G4GeometryManager.hh"
#include "G4PhysicalVolumeStore.hh"
#include "G4LogicalVolumeStore.hh"
#include "G4SolidStore.hh"
#include "G4LogicalSkinSurface.hh"
#include "G4LogicalBorderSurface.hh"
#include "G4RunManager.hh"


// Local Libraries
//
//#include "PMTSD.hh"
#include "DetectorConstruction.hh"
#include "DetectorMessenger.hh"
#include "PMTSD.hh"
#include "world.hh"
#include "wcdLagoCont.hh"
#include "wcdLagoCalo.hh"
#include "wcdpmt.hh"
#include "worldGround.hh"
#include "grdFloor.hh"


// C++ Libraries
//


DetectorConstruction::DetectorConstruction()
 : G4VUserDetectorConstruction()
{
   G4cout << "...DetectorConstruction..." << G4endl;

  expHall = new world();
  groundBase = new worldGround();
  grd = new grdFloor();

  wcdCont = new wcdLagoCont(); 
  wcdCalo = new wcdLagoCalo(); 
  pmt_det = new wcdpmt(); 
 
  wcdRadius = 93.*cm; 
  wcdHight = 142.*cm; 

  checkOverlaps = true;

  detecMess = new DetectorMessenger(this);
}


DetectorConstruction::~DetectorConstruction()
{}

// *************************
// Doing Mechanical Detector
// ************************* 

G4VPhysicalVolume* DetectorConstruction::Construct()
{ 
  G4GeometryManager::GetInstance()->OpenGeometry();
  G4PhysicalVolumeStore::GetInstance()->Clean();
  G4LogicalVolumeStore::GetInstance()->Clean();
  G4SolidStore::GetInstance()->Clean();
  G4LogicalSkinSurface::CleanSurfaceTable();
  G4LogicalBorderSurface::CleanSurfaceTable();

  return ConstructDetector();
}


G4VPhysicalVolume* DetectorConstruction::ConstructDetector()
{
  expHall->DefineMaterials();
  expHall->buildDetector(&checkOverlaps);

  groundBase->DefineMaterials();
  groundBase->buildDetector(expHall->getLogVolume(), &checkOverlaps);

  wcdCont->DefineMaterials();
  wcdCont->buildDetector(groundBase->getLogVolume(), &checkOverlaps, wcdRadius, wcdHight);

  wcdCalo->DefineMaterials();
  wcdCalo->buildDetector(wcdCont->getLogVolume(), wcdCont->getPhysVolume(), &checkOverlaps, wcdRadius, wcdHight);

  pmt_det->DefineMaterials();
  pmt_det->buildDetector(wcdCalo->getLogVolume(), wcdHight, &checkOverlaps);
 
  fwaterVolume = wcdCalo->getPhysVolume();

  grd->DefineMaterials();
  grd->buildDetector(wcdHight, groundBase->getLogVolume(), &checkOverlaps);

  return expHall->getPhysVolume();
}


void DetectorConstruction::setWcdRadius( G4double wcdR )
{
  this->wcdRadius = wcdR;

  wcdCont->getLogVolume()->RemoveDaughter(wcdCont->getPhysVolume());
  delete wcdCont->getPhysVolume();
  wcdCont->buildDetector(groundBase->getLogVolume(), &checkOverlaps, wcdRadius, wcdHight);

  wcdCalo->getLogVolume()->RemoveDaughter(wcdCalo->getPhysVolume());
  delete wcdCalo->getPhysVolume();
  wcdCalo->buildDetector(wcdCont->getLogVolume(), wcdCont->getPhysVolume(), &checkOverlaps, wcdRadius, wcdHight);

  pmt_det->getLogVolume()->RemoveDaughter(pmt_det->getPhysVolume());
  delete pmt_det->getPhysVolume();
  pmt_det->buildDetector(wcdCalo->getLogVolume(), wcdHight, &checkOverlaps);

  fwaterVolume = wcdCalo->getPhysVolume();

  grd->getLogVolume()->RemoveDaughter(grd->getPhysVolume());
  delete grd->getPhysVolume();
  grd->buildDetector(wcdHight, groundBase->getLogVolume(), &checkOverlaps);

  G4RunManager::GetRunManager()->GeometryHasBeenModified();
}


void DetectorConstruction::setWcdHight( G4double wcdH )
{
  this->wcdHight = wcdH;

  wcdCont->getLogVolume()->RemoveDaughter(wcdCont->getPhysVolume());
  delete wcdCont->getPhysVolume();
  wcdCont->buildDetector(groundBase->getLogVolume(), &checkOverlaps, wcdRadius, wcdHight);

  wcdCalo->getLogVolume()->RemoveDaughter(wcdCalo->getPhysVolume());
  delete wcdCalo->getPhysVolume();
  wcdCalo->buildDetector(wcdCont->getLogVolume(), wcdCont->getPhysVolume(), &checkOverlaps, wcdRadius, wcdHight);

  pmt_det->getLogVolume()->RemoveDaughter(pmt_det->getPhysVolume());
  delete pmt_det->getPhysVolume();
  pmt_det->buildDetector(wcdCalo->getLogVolume(), wcdHight, &checkOverlaps);

  fwaterVolume = wcdCalo->getPhysVolume();

  grd->getLogVolume()->RemoveDaughter(grd->getPhysVolume());
  delete grd->getPhysVolume();
  grd->buildDetector(wcdHight, groundBase->getLogVolume(), &checkOverlaps);

  G4RunManager::GetRunManager()->GeometryHasBeenModified();
}
