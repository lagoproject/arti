// Geant4 Libraries
//
#include "G4Material.hh"
#include "G4Element.hh"
#include "G4SystemOfUnits.hh"
#include "G4NistManager.hh"


// Local Libraries
//

#include "water2.hh"


water2::water2()
{
  G4cout << "...Creating water..." << G4endl;

  O = H = NULL;
  thewater = NULL;
  a = z = density = 0.;
}


water2::~water2()
{}

G4Material* water2::doWater()
{
  a = 1.01*g/mole;
  H = new G4Element("Hydrogen","H", 1,a); 
  
  a = 16.00*g/mole;
  O = new G4Element("Oxygen","O", 8,a);

  density = 1.00*g/cm3;

  thewater = new G4Material("Water",density,2);
  thewater->AddElement(H, 2);
  thewater->AddElement(O, 1);

  return thewater;
}


G4MaterialPropertiesTable* water2::doOpwater()
{

  G4double photonEnergy[] =
  {
    1.56962e-09*GeV, 1.58974e-09*GeV, 1.61039e-09*GeV, 1.63157e-09*GeV, 
    1.65333e-09*GeV, 1.67567e-09*GeV, 1.69863e-09*GeV, 1.72222e-09*GeV, 
    1.74647e-09*GeV, 1.77142e-09*GeV, 1.79710e-09*GeV, 1.82352e-09*GeV, 
    1.85074e-09*GeV, 1.87878e-09*GeV, 1.90769e-09*GeV, 1.93749e-09*GeV, 
    1.96825e-09*GeV, 1.99999e-09*GeV, 2.03278e-09*GeV, 2.06666e-09*GeV,
    2.10169e-09*GeV, 2.13793e-09*GeV, 2.17543e-09*GeV, 2.21428e-09*GeV, 
    2.25454e-09*GeV, 2.29629e-09*GeV, 2.33962e-09*GeV, 2.38461e-09*GeV, 
    2.43137e-09*GeV, 2.47999e-09*GeV, 2.53061e-09*GeV, 2.58333e-09*GeV, 
    2.63829e-09*GeV, 2.69565e-09*GeV, 2.75555e-09*GeV, 2.81817e-09*GeV, 
    2.88371e-09*GeV, 2.95237e-09*GeV, 3.02438e-09*GeV, 3.09999e-09*GeV,
    3.17948e-09*GeV, 3.26315e-09*GeV, 3.35134e-09*GeV, 3.44444e-09*GeV, 
    3.54285e-09*GeV, 3.64705e-09*GeV, 3.75757e-09*GeV, 3.87499e-09*GeV, 
    3.99999e-09*GeV, 4.13332e-09*GeV, 4.27585e-09*GeV, 4.42856e-09*GeV, 
    4.59258e-09*GeV, 4.76922e-09*GeV, 4.95999e-09*GeV, 5.16665e-09*GeV, 
    5.39129e-09*GeV, 5.63635e-09*GeV, 5.90475e-09*GeV, 6.19998e-09*GeV
  };
  const G4int nEntries = sizeof(photonEnergy)/sizeof(G4double);


  G4double refractiveIndex1[] =
  { 
    1.32885, 1.32906, 1.32927, 1.32948, 1.3297, 1.32992, 1.33014, 
    1.33037, 1.3306, 1.33084, 1.33109, 1.33134, 1.3316, 1.33186, 1.33213,
    1.33241, 1.3327, 1.33299, 1.33329, 1.33361, 1.33393, 1.33427, 1.33462,
    1.33498, 1.33536, 1.33576, 1.33617, 1.3366, 1.33705, 1.33753, 1.33803,
    1.33855, 1.33911, 1.3397, 1.34033, 1.341, 1.34172, 1.34248, 1.34331,
    1.34419, 1.34515, 1.3462, 1.34733, 1.34858, 1.34994, 1.35145, 1.35312,
    1.35498, 1.35707, 1.35943, 1.36211, 1.36518, 1.36872, 1.37287, 1.37776,
    1.38362, 1.39074, 1.39956, 1.41075, 1.42535
  };
  assert(sizeof(refractiveIndex1) == sizeof(photonEnergy));


  G4double ABWFF = 0.3;

  G4double absorption[] =
  {
    16.1419*cm*ABWFF,  18.278*cm*ABWFF, 21.0657*cm*ABWFF, 24.8568*cm*ABWFF, 30.3117*cm*ABWFF, 
    38.8341*cm*ABWFF, 54.0231*cm*ABWFF, 81.2306*cm*ABWFF, 120.909*cm*ABWFF, 160.238*cm*ABWFF, 
    193.771*cm*ABWFF, 215.017*cm*ABWFF, 227.747*cm*ABWFF,  243.85*cm*ABWFF, 294.036*cm*ABWFF, 
    321.647*cm*ABWFF,  342.81*cm*ABWFF, 362.827*cm*ABWFF, 378.041*cm*ABWFF, 449.378*cm*ABWFF,
    739.434*cm*ABWFF, 1114.23*cm*ABWFF, 1435.56*cm*ABWFF, 1611.06*cm*ABWFF, 1764.18*cm*ABWFF, 
    2100.95*cm*ABWFF,  2292.9*cm*ABWFF, 2431.33*cm*ABWFF,  3053.6*cm*ABWFF, 4838.23*cm*ABWFF, 
    6539.65*cm*ABWFF, 7682.63*cm*ABWFF, 9137.28*cm*ABWFF, 12220.9*cm*ABWFF, 15270.7*cm*ABWFF, 
    19051.5*cm*ABWFF, 23671.3*cm*ABWFF, 29191.1*cm*ABWFF, 35567.9*cm*ABWFF,   42583*cm*ABWFF,
    49779.6*cm*ABWFF, 56465.3*cm*ABWFF,   61830*cm*ABWFF, 65174.6*cm*ABWFF, 66143.7*cm*ABWFF,   
    64820*cm*ABWFF,   61635*cm*ABWFF, 57176.2*cm*ABWFF, 52012.1*cm*ABWFF, 46595.7*cm*ABWFF, 
    41242.1*cm*ABWFF, 36146.3*cm*ABWFF, 31415.4*cm*ABWFF, 27097.8*cm*ABWFF, 23205.7*cm*ABWFF, 
    19730.3*cm*ABWFF, 16651.6*cm*ABWFF, 13943.6*cm*ABWFF, 11578.1*cm*ABWFF, 9526.13*cm*ABWFF
  };
  assert(sizeof(absorption) == sizeof(photonEnergy));


  G4MaterialPropertiesTable* myMPT1 
    = new G4MaterialPropertiesTable();

  myMPT1
    ->AddProperty("RINDEX", 
        photonEnergy, refractiveIndex1, nEntries)
    ->SetSpline(true);

  myMPT1
    ->AddProperty("ABSLENGTH", photonEnergy, 
        absorption, nEntries)
    ->SetSpline(true);

  G4double MIEFF = 1.;

  //assume 100 times larger than the rayleigh scattering for now.
  G4double mie_water[] = 
  {
    7790020*cm*MIEFF, 7403010*cm*MIEFF, 7030610*cm*MIEFF, 6672440*cm*MIEFF, 6328120*cm*MIEFF, 
    5997320*cm*MIEFF, 5679650*cm*MIEFF, 5374770*cm*MIEFF, 5082340*cm*MIEFF, 4802000*cm*MIEFF, 
    4533420*cm*MIEFF, 4276280*cm*MIEFF, 4030220*cm*MIEFF, 3794950*cm*MIEFF, 3570120*cm*MIEFF,
    3355440*cm*MIEFF, 3150590*cm*MIEFF, 2955270*cm*MIEFF, 2769170*cm*MIEFF, 2592000*cm*MIEFF, 
    2423470*cm*MIEFF, 2263300*cm*MIEFF, 2111200*cm*MIEFF, 1966900*cm*MIEFF, 1830120*cm*MIEFF, 
    1700610*cm*MIEFF, 1578100*cm*MIEFF, 1462320*cm*MIEFF, 1353040*cm*MIEFF, 1250000*cm*MIEFF,
    1152960*cm*MIEFF, 1061680*cm*MIEFF,  975936*cm*MIEFF,  895491*cm*MIEFF,  820125*cm*MIEFF, 
    749619*cm*MIEFF,  683760*cm*MIEFF,  622339*cm*MIEFF,  565152*cm*MIEFF,  512000*cm*MIEFF, 
    462688*cm*MIEFF,  417027*cm*MIEFF,  374832*cm*MIEFF,  335923*cm*MIEFF,  300125*cm*MIEFF,
    267267*cm*MIEFF,  237184*cm*MIEFF,  209715*cm*MIEFF,  184704*cm*MIEFF,  162000*cm*MIEFF, 
    141456*cm*MIEFF,  122931*cm*MIEFF,  106288*cm*MIEFF, 91395.2*cm*MIEFF,   78125*cm*MIEFF, 
    66355.2*cm*MIEFF, 55968.2*cm*MIEFF, 46851.2*cm*MIEFF, 38896.2*cm*MIEFF, 32000*cm*MIEFF
  };
  assert(sizeof(mie_water) == sizeof(energy_water));

  // gforward, gbackward, forward backward ratio
  G4double mie_water_const[3]={0.4, 0., 1};

  myMPT1
    ->AddProperty("MIEHG", photonEnergy, mie_water, nEntries)
    ->SetSpline(true);
  myMPT1
    ->AddConstProperty("MIEHG_FORWARD",mie_water_const[0]);
  myMPT1
    ->AddConstProperty("MIEHG_BACKWARD",mie_water_const[1]);
  myMPT1
    ->AddConstProperty("MIEHG_FORWARD_RATIO",mie_water_const[2]);

  G4cout << "Water G4MaterialPropertiesTable" << G4endl;
  myMPT1->DumpTable();

  return  myMPT1; //  water->SetMaterialPropertiesTable(myMPT1);
}
