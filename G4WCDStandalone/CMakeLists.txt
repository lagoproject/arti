cmake_minimum_required(VERSION 3.20)

project(G4WCDStandalone VERSION 0.1.0 LANGUAGES CXX)

find_package(Geant4 11.2 REQUIRED)
find_package(ROOT 6 REQUIRED COMPONENTS Core RIO Tree)

if(NOT Geant4_multithreaded_FOUND)
  message(FATAL_ERROR "Geant4 must be built with multithreading enabled")
endif()

set(G4WCD_SOURCES
  src/main.cc
  src/WCDMaterials.cc
  src/PMTResponse.cc
  src/WCDConfig.cc
  src/WCDDetectorConstruction.cc
  src/WCDActionInitialization.cc
  src/WCDRunAction.cc
  src/WCDPhysicsList.cc
  src/WCDPMTSensitiveDetector.cc
  src/WCDPrimaryGeneratorAction.cc
  src/WCDEventAction.cc
  src/WCDSteppingAction.cc
  src/WCDStackingAction.cc
)

add_executable(G4WCDSimulator ${G4WCD_SOURCES})

target_compile_features(G4WCDSimulator PRIVATE cxx_std_17)
target_include_directories(G4WCDSimulator PRIVATE include)
target_link_libraries(G4WCDSimulator PRIVATE
  ${Geant4_LIBRARIES}
  ROOT::Core
  ROOT::RIO
  ROOT::Tree
)

install(TARGETS G4WCDSimulator RUNTIME DESTINATION bin)
install(DIRECTORY config/ DESTINATION share/G4WCDStandalone/config)

include(CTest)
if(BUILD_TESTING)
  add_executable(WCDPMTResponseTest tests/PMTResponseTest.cc src/PMTResponse.cc)
  target_compile_features(WCDPMTResponseTest PRIVATE cxx_std_17)
  target_include_directories(WCDPMTResponseTest PRIVATE include)
  target_link_libraries(WCDPMTResponseTest PRIVATE ${Geant4_LIBRARIES})
  add_test(NAME wcd_pmt_response COMMAND WCDPMTResponseTest)

  add_executable(WCDConfigTest tests/WCDConfigTest.cc src/WCDConfig.cc)
  target_compile_features(WCDConfigTest PRIVATE cxx_std_17)
  target_include_directories(WCDConfigTest PRIVATE include)
  add_test(NAME wcd_config COMMAND WCDConfigTest ${CMAKE_CURRENT_SOURCE_DIR}/tests/simulation-1.json ${CMAKE_CURRENT_SOURCE_DIR}/config/simulation.json)

  add_executable(WCDRootValidation tests/RootValidation.cc)
  target_compile_features(WCDRootValidation PRIVATE cxx_std_17)
  target_link_libraries(WCDRootValidation PRIVATE ROOT::Core ROOT::RIO ROOT::Tree)

  add_test(NAME wcd_run_single
    COMMAND G4WCDSimulator ${CMAKE_CURRENT_SOURCE_DIR}/tests/simulation-1.json)
  set_tests_properties(wcd_run_single PROPERTIES WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
  add_test(NAME wcd_run_mt
    COMMAND G4WCDSimulator ${CMAKE_CURRENT_SOURCE_DIR}/tests/simulation-2.json)
  set_tests_properties(wcd_run_mt PROPERTIES WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
  add_test(NAME wcd_root_validation
    COMMAND WCDRootValidation Detector-1.root Detector-2.root)
  set_tests_properties(wcd_root_validation PROPERTIES
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    DEPENDS "wcd_run_single;wcd_run_mt")
endif()
