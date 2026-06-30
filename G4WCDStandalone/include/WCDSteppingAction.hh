#pragma once

#include "G4UserSteppingAction.hh"

class WCDGeometryView;

class WCDSteppingAction final : public G4UserSteppingAction {
 public:
  explicit WCDSteppingAction(const WCDGeometryView* geometry) : geometry_(geometry) {}
  void UserSteppingAction(const G4Step* step) override;
 private:
  const WCDGeometryView* geometry_;
};
