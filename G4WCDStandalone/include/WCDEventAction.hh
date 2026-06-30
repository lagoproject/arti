#pragma once

#include "G4UserEventAction.hh"

#include <atomic>
#include <memory>

class G4Event;

class WCDEventAction final : public G4UserEventAction {
 public:
  WCDEventAction(std::shared_ptr<std::atomic<int>> completedEvents,
                 std::shared_ptr<std::atomic<int>> lastPrintedPercent,
                 int totalEvents);
  void EndOfEventAction(const G4Event* event) override;

 private:
  std::shared_ptr<std::atomic<int>> completedEvents_;
  std::shared_ptr<std::atomic<int>> lastPrintedPercent_;
  int totalEvents_;
};
