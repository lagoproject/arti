// implementation of the G4MPhysicsList class
#include "G4MPhysicsList.h"

#include "G4LossTableManager.hh"
#include "G4ProcessManager.hh"
#include "G4ParticleTypes.hh"
#include "G4ParticleTable.hh"
#include "FTFP_BERT.hh"
#include "QGSP_BERT_HP.hh"
#include "G4Gamma.hh"
#include "G4Electron.hh"
#include "G4Positron.hh"
#include "G4ProcessTable.hh"
#include "G4PionDecayMakeSpin.hh"
#include "G4DecayWithSpin.hh"
#include "G4DecayTable.hh"
#include "G4MuonDecayChannelWithSpin.hh"
#include "G4MuonRadiativeDecayChannelWithSpin.hh"
#include "G4RadioactiveDecayPhysics.hh"
#include "G4SystemOfUnits.hh"
#include "G4UnitsTable.hh"

#include "StepMax.hh"
#include "ExtraPhysics.hh"
#include "OpticalPhysics.hh"



G4MPhysicsList::G4MPhysicsList(G4String physName, G4int aVerbosity) : G4VModularPhysicsList()
{

	// setting verbose level
	verboseLevel = aVerbosity;

	G4LossTableManager::Instance();
	defaultCutValue  = 1.*mm;
	fCutForGamma     = defaultCutValue;
	fCutForElectron  = defaultCutValue;
	fCutForPositron  = defaultCutValue;

	// G4PhysListFactory factory;
	G4VModularPhysicsList* phys = NULL;
	if (physName == "QGSP_BERT_HP") {
		phys = new QGSP_BERT_HP(verboseLevel);
	} else {
		phys = new FTFP_BERT(verboseLevel);
	}
	phys->SetVerboseLevel(verboseLevel); 
	for (G4int i = 0; ; ++i) {
		G4VPhysicsConstructor* elem = const_cast<G4VPhysicsConstructor*> (phys->GetPhysics(i));
		if (elem == NULL) 
			break;
		
		if(verboseLevel) {
			G4cout << "RegisterPhysics: " << elem->GetPhysicsName() << G4endl;
		}
		elem->SetVerboseLevel(verboseLevel);
		RegisterPhysics(elem);
	}

	fAbsorptionOn = true;
	RegisterPhysics(new ExtraPhysics(verboseLevel));
	RegisterPhysics(fOpticalPhysics = new OpticalPhysics(fAbsorptionOn));
	RegisterPhysics(new G4RadioactiveDecayPhysics(verboseLevel));

	fStepMaxProcess = new StepMax();
	fStepMaxProcess->SetVerboseLevel(verboseLevel);

}

G4MPhysicsList::~G4MPhysicsList()
{
}

void 
G4MPhysicsList::ClearPhysics()
{
	for (G4PhysConstVector::iterator p  = fPhysicsVector->begin(); p != fPhysicsVector->end(); ++p) {
		delete (*p);
	}
	
	fPhysicsVector->clear();
}

void 
G4MPhysicsList::ConstructParticle()
{
	G4VModularPhysicsList::ConstructParticle();

	G4DecayTable* MuonPlusDecayTable = new G4DecayTable();
	MuonPlusDecayTable->Insert(new G4MuonDecayChannelWithSpin("mu+",0.986));
	MuonPlusDecayTable->Insert(new G4MuonRadiativeDecayChannelWithSpin("mu+",0.014));
	G4MuonPlus::MuonPlusDefinition()->SetDecayTable(MuonPlusDecayTable);
	G4DecayTable* MuonMinusDecayTable = new G4DecayTable();
	MuonMinusDecayTable->Insert(new G4MuonDecayChannelWithSpin("mu-",0.986));
	MuonMinusDecayTable->Insert(new G4MuonRadiativeDecayChannelWithSpin("mu-",0.014));
	G4MuonMinus::MuonMinusDefinition()->SetDecayTable(MuonMinusDecayTable);

}

//....oooOO0OOooo........oooOO0OOooo........oooOO0OOooo........oooOO0OOooo......

void 
G4MPhysicsList::ConstructProcess()
{
	G4VModularPhysicsList::ConstructProcess();

	SetVerbose(0);

	G4DecayWithSpin* decayWithSpin = new G4DecayWithSpin();
	G4ProcessTable* processTable = G4ProcessTable::GetProcessTable();

	G4VProcess* decay;
	decay = processTable->FindProcess("Decay",G4MuonPlus::MuonPlus());

	G4ProcessManager* pManager;
	pManager = G4MuonPlus::MuonPlus()->GetProcessManager();

	if (pManager) {
		pManager->SetVerboseLevel(verboseLevel);
		if (decay) {
			pManager->RemoveProcess(decay);
		}
		pManager->AddProcess(decayWithSpin);
		// set ordering for PostStepDoIt and AtRestDoIt
		pManager->SetProcessOrdering(decayWithSpin, idxPostStep);
		pManager->SetProcessOrdering(decayWithSpin, idxAtRest);
	}

	decay = processTable->FindProcess("Decay",G4MuonMinus::MuonMinus());
	pManager = G4MuonMinus::MuonMinus()->GetProcessManager();

	if (pManager) {
		pManager->SetVerboseLevel(verboseLevel);
		if (decay) {
			pManager->RemoveProcess(decay);
		}
		pManager->AddProcess(decayWithSpin);
		// set ordering for PostStepDoIt and AtRestDoIt
		pManager->SetProcessOrdering(decayWithSpin, idxPostStep);
		pManager->SetProcessOrdering(decayWithSpin, idxAtRest);
	}

	G4PionDecayMakeSpin* poldecay = new G4PionDecayMakeSpin();
	decay = processTable->FindProcess("Decay",G4PionPlus::PionPlus());
	pManager = G4PionPlus::PionPlus()->GetProcessManager();

	if (pManager) {
		pManager->SetVerboseLevel(verboseLevel);
		if (decay) {
			pManager->RemoveProcess(decay);
		}
		pManager->AddProcess(poldecay);
		// set ordering for PostStepDoIt and AtRestDoIt
		pManager ->SetProcessOrdering(poldecay, idxPostStep);
		pManager ->SetProcessOrdering(poldecay, idxAtRest);
	}

	decay = processTable->FindProcess("Decay",G4PionMinus::PionMinus());
	pManager = G4PionMinus::PionMinus()->GetProcessManager();

	if (pManager) {
		pManager->SetVerboseLevel(verboseLevel);
		if (decay) {
			pManager->RemoveProcess(decay);
		}
		pManager->AddProcess(poldecay);
		// set ordering for PostStepDoIt and AtRestDoIt
		pManager ->SetProcessOrdering(poldecay, idxPostStep);
		pManager ->SetProcessOrdering(poldecay, idxAtRest);
	}

	AddStepMax();

}

void 
G4MPhysicsList::RemoveFromPhysicsList(const G4String& name)
{
	G4bool success = false;
	for (G4PhysConstVector::iterator p  = fPhysicsVector->begin();
			p != fPhysicsVector->end(); ++p) {
			G4VPhysicsConstructor* e = (*p);
			if (e->GetPhysicsName() == name) {
				 fPhysicsVector->erase(p);
				 success = true;
				 break;
			}
	}
	if (!success) {
		 G4ExceptionDescription message;
		 message << "PhysicsList::RemoveFromEMPhysicsList "<< name << "not found";
		 G4Exception("example PhysicsList::RemoveFromPhysicsList()",
		 "ExamPhysicsList01",FatalException,message);
	}
}

void 
G4MPhysicsList::SetAbsorption(G4bool toggle)
{
	fAbsorptionOn = toggle;
 	RemoveFromPhysicsList("Optical");
 	fPhysicsVector->push_back(fOpticalPhysics = new OpticalPhysics(toggle));
 	fOpticalPhysics->ConstructProcess();
}

void 
G4MPhysicsList::SetCuts()
{
	if (verboseLevel > 0) {
			G4cout << "PhysicsList::SetCuts:";
			G4cout << "CutLength : " << G4BestUnit(defaultCutValue,"Length") << G4endl;
	}

	// set cut values for gamma at first and for e- second and next for e+,
	// because some processes for e+/e- need cut values for gamma
	SetCutValue(fCutForGamma, "gamma");
	SetCutValue(fCutForElectron, "e-");
	SetCutValue(fCutForPositron, "e+");

	if (verboseLevel>0) {
		DumpCutValuesTable();
	}
}

void 
G4MPhysicsList::SetCutForGamma(G4double cut)
{
	fCutForGamma = cut;
	SetParticleCuts(fCutForGamma, G4Gamma::Gamma());
}

void 
G4MPhysicsList::SetCutForElectron(G4double cut)
{
	fCutForElectron = cut;
	SetParticleCuts(fCutForElectron, G4Electron::Electron());
}

void 
G4MPhysicsList::SetCutForPositron(G4double cut)
{
	fCutForPositron = cut;
	SetParticleCuts(fCutForPositron, G4Positron::Positron());
}

void 
G4MPhysicsList::SetStepMax(G4double step)
{
	fStepMaxProcess->SetStepMax(step);
}

StepMax* 
G4MPhysicsList::GetStepMaxProcess()
{
	return fStepMaxProcess;
}

void 
G4MPhysicsList::AddStepMax()
{
	// Step limitation seen as a process

	auto particleIterator=GetParticleIterator();
	particleIterator->reset();
	while ((*particleIterator)()) {
		G4ParticleDefinition* particle = particleIterator->value();
		G4ProcessManager* pmanager = particle->GetProcessManager();

		if (fStepMaxProcess->IsApplicable(*particle) && !particle->IsShortLived()) {
			if (pmanager) {
				pmanager->SetVerboseLevel(verboseLevel);
				pmanager->AddDiscreteProcess(fStepMaxProcess);
			}
		}
	}
}


void 
G4MPhysicsList::SetNbOfPhotonsCerenkov(G4int maxNumber)
{
	fOpticalPhysics->SetNbOfPhotonsCerenkov(maxNumber);
}


void 
G4MPhysicsList::SetVerbose(G4int verbose)
{
	fOpticalPhysics->GetCerenkovProcess()->SetVerboseLevel(verbose);
	fOpticalPhysics->GetScintillationProcess()->SetVerboseLevel(verbose);
	fOpticalPhysics->GetAbsorptionProcess()->SetVerboseLevel(verbose);
	fOpticalPhysics->GetRayleighScatteringProcess()->SetVerboseLevel(verbose);
	fOpticalPhysics->GetMieHGScatteringProcess()->SetVerboseLevel(verbose);
	fOpticalPhysics->GetBoundaryProcess()->SetVerboseLevel(verbose);
}
