#include "PMTResponse.hh"

#include <cmath>
#include <iostream>

int main() {
  try {
    PMTResponse response("XP1805", .70);
    const auto equal = [](double actual, double expected) { return std::abs(actual - expected) < 1.e-12; };
    if (!equal(response.QuantumEfficiency(275.), .01) || !equal(response.QuantumEfficiency(325.), .03) ||
        !equal(response.QuantumEfficiency(375.), .20) || !equal(response.QuantumEfficiency(425.), .25) ||
        !equal(response.QuantumEfficiency(475.), .20) || !equal(response.QuantumEfficiency(525.), .14) ||
        !equal(response.QuantumEfficiency(575.), .07) || !equal(response.QuantumEfficiency(625.), .03) ||
        !equal(response.QuantumEfficiency(675.), .01) || response.QuantumEfficiency(200.) != 0. ||
        response.QuantumEfficiency(700.) != 0.) return 1;
    if (response.DetectionProbability(3.54) <= 0. || response.DetectionProbability(10.) != 0.) return 1;
    bool rejected = false;
    try { PMTResponse invalid("unknown", .70); } catch (...) { rejected = true; }
    return rejected ? 0 : 1;
  } catch (const std::exception& error) {
    std::cerr << error.what() << '\n';
    return 1;
  }
}
