#include "WCDEventAction.hh"

#include "G4Event.hh"
#include "G4RunManager.hh"
#include "WCDResults.hh"

#include <algorithm>
#include <iostream>
#include <utility>

WCDEventAction::WCDEventAction(std::shared_ptr<std::atomic<int>> completedEvents,
                               std::shared_ptr<std::atomic<int>> lastPrintedPercent,
                               int totalEvents)
    : completedEvents_(std::move(completedEvents)),
      lastPrintedPercent_(std::move(lastPrintedPercent)),
      totalEvents_(totalEvents) {}

void WCDEventAction::EndOfEventAction(const G4Event* event) {
  auto* results = static_cast<WCDEventResults*>(event->GetUserInformation());
  if (results) {
    auto& output = static_cast<WCDRun*>(G4RunManager::GetRunManager()->GetNonConstCurrentRun())->results;
    output.insert(output.end(), results->Values().begin(), results->Values().end());
  }

  if (totalEvents_ <= 0) return;
  const int completed = ++(*completedEvents_);
  const int percent = std::min(100, completed * 100 / totalEvents_);
  int previous = lastPrintedPercent_->load();
  while (percent > previous && !lastPrintedPercent_->compare_exchange_weak(previous, percent)) {}
  if (percent > previous) {
    std::cerr << "Simulated " << completed << "/" << totalEvents_
              << " particles (" << percent << "%)" << (percent == 100 ? "\n" : "\r")
              << std::flush;
  }
}
