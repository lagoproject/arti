#pragma once

#include "G4UserRunAction.hh"
#include "WCDTypes.hh"

#include <string>

class WCDRunAction final : public G4UserRunAction {
 public:
  WCDRunAction(Settings settings, std::string configuration);
  G4Run* GenerateRun() override;
  void EndOfRunAction(const G4Run* run) override;
 private:
  Settings settings_;
  std::string configuration_;
};
