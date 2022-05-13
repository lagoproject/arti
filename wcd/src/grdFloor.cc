// Database of materials:
// http://geant4-userdoc.web.cern.ch/geant4-userdoc/UsersGuides/ForApplicationDeveloper/BackupVersions/V9.3/html/apas09.html


// Geant4 Libraries
//
#include "G4Element.hh"
#include "G4Material.hh"
#include "G4NistManager.hh"



// Local Libraries
//
#include "grdFloor.hh"


grdFloor::grdFloor()
{
  G4cout << "...Creating Ground..." << G4endl;
}


grdFloor::~grdFloor()
{}


void grdFloor::DefineMaterials()
{
  G4double a = 0.;
  G4double z;
  G4String symbol;
  G4int natoms;

  G4double density = 2.65*g/cm3;

	// Creating Si
	//
	a = 28.09*g/mole;
  G4Element* elSi 
		= new G4Element(
				"Silicon", 
				symbol="Si", 
				z=14.,
        a
				);

  // Creating Oxigen
	//
	a = 16.00*g/mole;
	G4Element* elO  
		= new G4Element(
        "Oxygen",
				symbol="O",
        z= 8.,
        a
        );

	// Creating Standard Rock
	//
	grdFloor_mat = new G4Material(
      "Rockgrd",
      density,
      2
      );

	grdFloor_mat->AddElement(elSi, natoms=1);
	grdFloor_mat->AddElement(elO,  natoms=2);
}


void grdFloor::buildDetector(G4double grd_size, G4LogicalVolume* log_mother, G4bool* overLaps)
{
  //grd_size = grd_size * 0.5;
  G4double posZ = grd_size + grd_size/1.9; // *  0.3;

  grdFloor_geo
    = new G4Box(
        "Ground_geo",
        grd_size*10.,
        grd_size*10.,
        grd_size
        );

  grdFloor_log
    = new G4LogicalVolume(
        grdFloor_geo,
        grdFloor_mat,
        grdFloor_geo->GetName()
        );

  grdFloor_phys 
    = new G4PVPlacement(
        0,
        G4ThreeVector(0.*m, 0.*m, -posZ),
        grdFloor_log,
        grdFloor_geo->GetName(),
        log_mother,
        false,
        0,
        overLaps
        );
}


G4VPhysicalVolume* grdFloor::getPhysVolume()
{
  return grdFloor_phys;
}


G4LogicalVolume* grdFloor::getLogVolume()
{
  return grdFloor_log;
}
