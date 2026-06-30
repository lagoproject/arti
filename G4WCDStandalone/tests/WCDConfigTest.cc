#include "WCDConfig.hh"

#include <iostream>
#include <stdexcept>

int main(int argc, char** argv) try {
  if (argc != 3) throw std::runtime_error("usage: WCDConfigTest native.json fast.json");
  const auto native = WCDConfig::LoadSettings(argv[1]);
  const auto fast = WCDConfig::LoadSettings(argv[2]);
  if (native.inputMode != "native" || native.simulationMode != "full" || !native.geoVis || !native.trajVis)
    throw std::runtime_error("default/full native configuration parsed incorrectly");
  if (fast.inputMode != "arti" || fast.simulationMode != "fast" || fast.geoVis || fast.trajVis)
    throw std::runtime_error("Input.Mode and Simulation.Mode were not parsed independently");
  return 0;
} catch (const std::exception& error) {
  std::cerr << "WCDConfigTest: " << error.what() << '\n';
  return 1;
}
