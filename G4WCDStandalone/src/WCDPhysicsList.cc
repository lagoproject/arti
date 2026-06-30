#include "WCDPhysicsList.hh"

#include "G4OpticalPhysics.hh"
#include "G4VModularPhysicsList.hh"
#include "QGSP_BERT_HP.hh"

G4VUserPhysicsList* CreateWCDPhysicsList() {
  auto* physics = new QGSP_BERT_HP;
  physics->RegisterPhysics(new G4OpticalPhysics);
  return physics;
}
