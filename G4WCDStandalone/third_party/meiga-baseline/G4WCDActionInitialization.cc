#include "G4WCDActionInitialization.h"
#include "G4MPrimaryGeneratorAction.h"
#include "G4WCDRunAction.h"
#include "G4WCDEventAction.h"
#include "G4WCDSteppingAction.h"
#include "G4WCDTrackingAction.h"
#include "G4WCDStackingAction.h"

G4WCDActionInitialization::G4WCDActionInitialization(Event &aEvent) 
  : G4VUserActionInitialization(), fEvent(aEvent)
{
}

void 
G4WCDActionInitialization::BuildForMaster() const
{
  SetUserAction(new G4WCDRunAction());
}

void 
G4WCDActionInitialization::Build() const
{
    SetUserAction(new G4MPrimaryGeneratorAction(fEvent));
    SetUserAction(new G4WCDEventAction());
    SetUserAction(new G4WCDStackingAction(fEvent));
    SetUserAction(new G4WCDSteppingAction());
}
