#ifndef water_hh 
#define water_hh 1


// Geant4 Libraries
//
#include "G4Material.hh"
#include "G4Element.hh"


// Local Libraries
//


class water
{
  public:
    water();
    ~water();

    G4Material* doWater();
    G4MaterialPropertiesTable* doOpwater();

  private:
    G4Element* O;
    G4Element* H;
    G4double a, z, density;
    
    G4Material* thewater;
};
#endif
