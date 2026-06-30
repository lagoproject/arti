#pragma once

#include "G4VUserActionInitialization.hh"
#include "WCDTypes.hh"

#include <atomic>
#include <memory>
#include <string>
#include <vector>

class WCDGeometryView;

class WCDActionInitialization final : public G4VUserActionInitialization {
 public:
  WCDActionInitialization(const WCDGeometryView* geometry,
                          std::shared_ptr<const std::vector<Primary>> inputs,
                          Settings settings, Injection injection, std::string configuration);
  void BuildForMaster() const override;
  void Build() const override;

 private:
  const WCDGeometryView* geometry_;
  std::shared_ptr<const std::vector<Primary>> inputs_;
  Settings settings_;
  Injection injection_;
  std::string configuration_;
  std::shared_ptr<std::atomic<int>> completedEvents_;
  std::shared_ptr<std::atomic<int>> lastPrintedPercent_;
};
