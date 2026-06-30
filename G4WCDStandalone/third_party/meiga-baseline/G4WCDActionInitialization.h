#ifndef G4WCDActionInitialization_h
#define G4WCDActionInitialization_h 1

#include "G4VUserActionInitialization.hh"

class Event;
class G4WCDDetectorConstruction;

class G4WCDActionInitialization : public G4VUserActionInitialization
{
    public:
        G4WCDActionInitialization(Event &aEvent);
        ~G4WCDActionInitialization() override = default;

        void BuildForMaster() const override;
        void Build() const override;

    private:
        Event &fEvent;

};

#endif