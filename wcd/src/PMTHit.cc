
// Geant4 Libraries
// 
#include "G4SystemOfUnits.hh"
#include "Randomize.hh"


// Local Libraries
// 
#include "PMTHit.hh"


G4ThreadLocal G4Allocator<PMTHit>* PMTHitAllocator=0;


PMTHit::PMTHit()
  : waveLength(0.)
{}


PMTHit::~PMTHit()
{}

G4int PMTHit::askDetected(G4double phoEner)
{

  waveLength = 1240. / (phoEner/(1.*eV));
  
  if(waveLength >= 250. && waveLength < 300.)
  {
    if(G4UniformRand() <= 0.01)
      return 1;
    else 
      return 0;
  }
  else if(waveLength >= 300. && waveLength < 350.)
  {
    if(G4UniformRand() <= 0.03*probaCollect) 
      return 1;
    else
      return 0;
  }
  else if(waveLength >= 350. && waveLength < 400.)
  {
    if(G4UniformRand() <= 0.2*probaCollect) 
      return 1;
    else 
      return 0;
  }
  else if(waveLength >= 400. && waveLength < 450.)
  {
    if(G4UniformRand() <= 0.25*probaCollect)
      return 1;
    else
      return 0;
  }
  else if(waveLength >= 450. && waveLength < 500.)
  {
    if(G4UniformRand() <= 0.2*probaCollect) 
      return 1;
    else 
      return 0;
  }
  else if(waveLength >= 500. && waveLength < 550.)
  {
    if(G4UniformRand() <= 0.14*probaCollect)
      return 1;
    else
      return 0;
  }
  else if(waveLength >= 550. && waveLength < 600.)
  {
    if(G4UniformRand() <= 0.07*probaCollect)
      return 1;
    else 
      return
        0;
  }
  else if(waveLength >= 600. && waveLength < 650.)
  {
    if(G4UniformRand() <= 0.03*probaCollect)
      return 1;
    else 
      return 0;
  }
  else if(waveLength >= 650. && waveLength < 700.)
  {
    if(G4UniformRand() <= 0.06*probaCollect)
      return 1;
    else 
      return 0;
  }
  else
   return 0;
}

