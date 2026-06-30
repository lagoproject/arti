#include "WCDActionInitialization.hh"

#include "WCDEventAction.hh"
#include "WCDPrimaryGeneratorAction.hh"
#include "WCDRunAction.hh"
#include "WCDSteppingAction.hh"
#include "WCDStackingAction.hh"

#include <utility>

WCDActionInitialization::WCDActionInitialization(const WCDGeometryView* geometry,
    std::shared_ptr<const std::vector<Primary>> inputs, Settings settings, Injection injection,
    std::string configuration)
    : geometry_(geometry), inputs_(std::move(inputs)), settings_(std::move(settings)), injection_(std::move(injection)),
      configuration_(std::move(configuration)),
      completedEvents_(std::make_shared<std::atomic<int>>(0)),
      lastPrintedPercent_(std::make_shared<std::atomic<int>>(-1)) {}

void WCDActionInitialization::BuildForMaster() const {
  SetUserAction(new WCDRunAction(settings_, configuration_));
}

void WCDActionInitialization::Build() const {
  SetUserAction(new WCDPrimaryGeneratorAction(inputs_, injection_, settings_.seed));
  SetUserAction(new WCDRunAction(settings_, configuration_));
  SetUserAction(new WCDEventAction(completedEvents_, lastPrintedPercent_, static_cast<int>(inputs_->size())));
  SetUserAction(new WCDSteppingAction(geometry_));
  SetUserAction(new WCDStackingAction(settings_.simulationMode == "fast", settings_.pmtModel, settings_.collectionEfficiency));
}
