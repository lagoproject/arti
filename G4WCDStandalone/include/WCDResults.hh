#pragma once

#include "G4Run.hh"
#include "G4VUserEventInformation.hh"
#include "WCDTypes.hh"

#include <utility>
#include <vector>

class WCDEventResults final : public G4VUserEventInformation {
 public:
  explicit WCDEventResults(Result primary) : primary_(std::move(primary)) {}
  void Print() const override {}
  Result& Entered(int detectorId) {
    for (auto& result : results_) if (result.detectorId == detectorId) return result;
    Result result = primary_;
    result.detectorId = detectorId;
    result.enteredWater = true;
    results_.push_back(result);
    return results_.back();
  }
  Result* Find(int detectorId) {
    for (auto& result : results_) if (result.detectorId == detectorId) return &result;
    return nullptr;
  }
  const std::vector<Result>& Values() const { return results_; }
 private:
  Result primary_;
  std::vector<Result> results_;
};

class WCDRun final : public G4Run {
 public:
  std::vector<Result> results;
  void Merge(const G4Run* run) override {
    const auto* worker = static_cast<const WCDRun*>(run);
    results.insert(results.end(), worker->results.begin(), worker->results.end());
    G4Run::Merge(run);
  }
};
