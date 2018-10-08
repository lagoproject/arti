// Geant4 Libraries
//
#include "Randomize.hh"
#include "G4Event.hh"
#include "G4ParticleGun.hh"
#include "G4ParticleTable.hh"
#include "G4ParticleDefinition.hh"
#include "G4SystemOfUnits.hh"


// Local Libraries
//
#include "PrimaryGeneratorAction.hh"
#include "PrimaryGeneratorMessenger.hh"
#include "PrimarySpectrum.hh"


PrimaryGeneratorAction::PrimaryGeneratorAction(PrimarySpectrum* crkPart)
  : G4VUserPrimaryGeneratorAction(), 
  fCrkPar(crkPart),
  fParticleGun(0)
{
  G4cout << "...PrimaryGeneratorAction..." << G4endl;

  G4int n_particle = 1;
  fParticleGun = new G4ParticleGun(n_particle);

  //create a messenger for this class
  fGunMessenger = new PrimaryGeneratorMessenger(this);


  //default kinematic
  //
  G4ParticleTable* particleTable 
    = G4ParticleTable::GetParticleTable();

  primaryId = "mu-";
  G4ParticleDefinition* particle 
    = particleTable->FindParticle(primaryId);

  fParticleGun->SetParticleDefinition(particle);
//  fParticleGun->SetParticleTime(0.0*ns);
  fParticleGun
    ->SetParticlePosition(G4ThreeVector(30.*cm, 30.*cm, 70.*cm));//.0*cm, 61.0*cm, 0.*cm));//61.0*cm));
  fParticleGun
    ->SetParticleMomentumDirection(G4ThreeVector(0., 0., -1.));
    
}


PrimaryGeneratorAction::~PrimaryGeneratorAction()
{
  delete fParticleGun;
  delete fGunMessenger;
}

//....oooOO0OOooo........oooOO0OOooo........oooOO0OOooo........oooOO0OOooo......

void PrimaryGeneratorAction::GeneratePrimaries(G4Event* anEvent)
{
  //fParticleGun->SetParticleMomentum(G4ThreeVector(enerPart,0,0));
  //fParticleGun->GeneratePrimaryVertex(anEvent);
  //enerPart += 0.1; //++;

  fCrkPar->primaryPosition();
  fCrkPar->primaryMomento();

  //parPosDir.primaryPosition();
  //parPosDir.primaryMomento();

	//position = parPosDir.particlePosition;
	//direction = parPosDir.particleDirection;
	//G4String parid = parPosDir.parId;
  //parPosDir.primaryPosition();
  //parPosDir.primaryMomento();

  position = fCrkPar->particlePosition;
  direction = fCrkPar->particleDirection;
  primaryId = fCrkPar->parId;

	G4ParticleTable* particleTable 
		= G4ParticleTable::GetParticleTable();
	
	G4ParticleDefinition* particle 
		= particleTable->FindParticle(primaryId);

  fParticleGun->SetParticleDefinition(particle);
  fParticleGun->SetParticlePosition(position);
  fParticleGun->SetParticleMomentum(direction);
 

  fParticleGun->GeneratePrimaryVertex(anEvent);

}


void PrimaryGeneratorAction::SetOptPhotonPolar()
{
 G4double angle = G4UniformRand() * 360.0*deg;
 SetOptPhotonPolar(angle);
}


void PrimaryGeneratorAction::SetOptPhotonPolar(G4double angle)
{
 if (fParticleGun->GetParticleDefinition()->GetParticleName()!="opticalphoton")
   {
     G4cout << "--> warning from PrimaryGeneratorAction::SetOptPhotonPolar() :"
               "the particleGun is not an opticalphoton" << G4endl;
     return;
   }

 G4ThreeVector normal (1., 0., 0.);
 G4ThreeVector kphoton = fParticleGun->GetParticleMomentumDirection();
 G4ThreeVector product = normal.cross(kphoton);
 G4double modul2       = product*product;
 
 G4ThreeVector e_perpend (0., 0., 1.);
 if (modul2 > 0.) e_perpend = (1./std::sqrt(modul2))*product;
 G4ThreeVector e_paralle    = e_perpend.cross(kphoton);
 
 G4ThreeVector polar = std::cos(angle)*e_paralle + std::sin(angle)*e_perpend;
 fParticleGun->SetParticlePolarization(polar);
}

