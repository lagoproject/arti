# Standalone Multithreaded G4WCDSimulator

Before to keep reading, go to meiga directory, read the project there inside
and keep reading this file. 

## Goal

Create a new repository outside Meiga for simulating the response of water
Cherenkov detectors (WCDs) to EAS particles. The executable must use Geant4
multithreading and write one ROOT tree entry for each primary particle that is
confirmed to enter a WCD water volume.

Do not depend on, link against, or include Meiga libraries in the new project.
Meiga files listed below are a baseline/reference only and must be copied into
the new repository before being adapted.

## Prerequisites

- CMake 3.20 or newer.
- C++17 compiler.
- Geant4 11.2 or newer built with multithreading enabled.
- ROOT 6 with the `Core`, `RIO`, and `Tree` components.

Fail CMake configuration if the discovered Geant4 installation has no MT
support. ROOT output is written only on the Geant4 master thread.

## Required ROOT Output

Create one `TTree` named `Detector`. There is no separate tree per detector
and no `events` branch. Each tree entry is one `(primary particle, WCD)` pair
for which the primary enters the tank water volume.

```text
TTree: Detector

Int_t    partId
Int_t    DetectorId

Double_t px                 // GeV/c
Double_t py                 // GeV/c
Double_t pz                 // GeV/c

Double_t x                  // m; primary injection position
Double_t y                  // m
Double_t z                  // m

Double_t energy_deposit     // MeV; primary track only

Int_t    charge_pmt_0       // detected photoelectrons
Int_t    charge_pmt_1       // detected photoelectrons
Int_t    charge_pmt_2       // detected photoelectrons
```

Rules:

- Do not write PE-time distributions.
- The three PMT-charge fields are always present.
- Write zero for a PMT that is absent or that detects no photoelectrons.
- Keep `energy_deposit` compatible with the existing simulator: sum only steps
  whose track ID is `1` (the primary), within the WCD water volume.
- A primary that does not enter water produces no output row.
- If a primary enters more than one WCD, write one row for each entered WCD,
  using the corresponding `DetectorId`.
- Use an internal Geant4 event ID for ordering and merging, but do not add it
  to the ROOT schema unless requirements change.

## Recommended Project Layout

```text
G4WCDStandalone/
  CMakeLists.txt
  README.md
  LICENSE
  config/
    detector.xml
    simulation.json
  include/
    WCDDetectorConstruction.hh
    WCDActionInitialization.hh
    WCDPrimaryGeneratorAction.hh
    WCDEventAction.hh
    WCDRunAction.hh
    WCDRun.hh
    WCDSteppingAction.hh
    WCDPMTSensitiveDetector.hh
    WCDWaterSensitiveDetector.hh
    WCDEventResult.hh
    WCDRootWriter.hh
    WCDGeometry.hh
    WCDMaterials.hh
    PMTResponse.hh
    WCDPhysicsList.hh
  src/
    ...matching implementation files...
  tests/
  macros/
```

Keep configuration, geometry, event data, and ROOT output as separate
components. Do not reintroduce a mutable global application/event container.

## Baseline Files to Copy From Meiga

Copy these files into the standalone repository first. Preserve author and
license notices, then rename/refactor to remove Meiga dependencies.

### Copy and adapt

- `src/Applications/G4WCDSimulator/G4WCDConstruction.{cc,h}`
  - Baseline world/WCD construction only.
  - Replace the `Event`/`Detector` dependencies with standalone detector
    configuration and geometry classes.
- `src/Applications/G4WCDSimulator/G4WCDActionInitialization.{cc,h}`
  - Baseline Geant4 action registration.
- `src/Applications/G4WCDSimulator/G4WCDStackingAction.{cc,h}`
  - Baseline optional fast optical-photon rejection behavior.
- `src/G4Models/WCD.{cc,h}`
  - Baseline WCD tank, liner, PMT geometry, and two/three-PMT layout.
  - Refactor it so it contains no Meiga `Detector`, `Event`, or static logical
    volume state.
- `src/G4Models/Materials.{cc,h}`
  - Baseline water, HDPE, Pyrex, liner optical surface, and optical properties.
- `src/Framework/Detector/OptDevice.{cc,h}`
  - Baseline PMT dimensions, wavelength range, quantum efficiency, and PE
    detection logic. Rename to `PMTResponse` if appropriate.
- `src/G4Models/OpticalPhysics.{cc,hh}`
  - Baseline optical physics configuration.
- `src/G4Models/G4MPhysicsList.{cc,h}`, `ExtraPhysics.{cc,hh}`, and
  `StepMax.{cc,hh}`
  - Baseline physics-list behavior. Simplify only after the standalone
    executable reproduces the desired serial physics response.
- `src/Utilities/Geometry.{cc,h}`
  - Optional vector-conversion helpers.
- `src/Applications/G4WCDSimulator/DetectorList.xml` and
  `G4WCDSimulator.json`
  - Baseline configuration examples only; define a standalone schema.

### Do not copy as architecture

Do not carry these designs into the new project:

- `Framework/Event`, `Framework/SimData`, and `Framework/Detector`.
- `IO/DataWriter` and JSON output code.
- `ConfigManager`, `G4MBaseApplication`, or the Meiga application base.
- The serial `BeamOn(1)` loop from `G4WCDSimulator.cc`.
- Shared `currentParticle`, shared result vectors, or static detector logical
  volumes used as mutable state.

`Particle.{cc,h}` and `ParticleFiller.{cc,h}` may be used only as format
references for ARTI/EAS input. Prefer a compact immutable `PrimaryInput` type
in the standalone project.

## Multithreaded Architecture

### Run manager

1. Read the requested thread count from configuration, for example
   `Simulation.Threads`.
2. Create `G4MTRunManager` through `G4RunManagerFactory` with the MT type.
3. Call `SetNumberOfThreads(threads)` before `Initialize()`.
4. Submit all primaries in one call: `BeamOn(numberOfEvents)`.
5. Disable interactive visualization by default in MT batch runs.

### Immutable input and primary generation

1. Parse input particles before Geant4 starts workers.
2. Store immutable primary inputs in a vector shared read-only by worker
   actions.
3. In `GeneratePrimaries(G4Event*)`, select the input by
   `event->GetEventID()`.
4. Copy that primary into event-local state before generating injection
   position or momentum adjustments.
5. Keep EcoMug and all random generators local to each worker action.
6. Derive reproducible per-event seeds from a configured base seed and event
   ID. The result must not depend on worker scheduling or thread count.

### Event-local results

Define a plain event-result type, conceptually:

```cpp
struct WCDResult {
  int eventId;
  int partId;
  int detectorId;
  double pxGeV, pyGeV, pzGeV;
  double xM, yM, zM;
  double energyDepositMeV;
  int charge[3];
  bool enteredWater;
};
```

Attach it to the `G4Event` through a `G4VUserEventInformation` subclass, or
keep it in an event action that is private to each worker. Never append worker
results directly to a shared `std::vector` or ROOT tree.

### Sensitive detectors and entry filter

1. Build geometry once in `Construct()`.
2. Create worker-local sensitive detectors in `ConstructSDandField()`.
   Do not rely on `G4VSensitiveDetector::Clone()` returning `nullptr`.
3. Identify the water logical volume by pointer, not by a string name.
4. In a stepping action or water sensitive detector, detect primary entry with:
   - track ID equal to `1`;
   - post-step physical/logical volume equal to the WCD water volume; and
   - pre-step volume outside that water volume.
5. Set `enteredWater = true` only on that transition. Primaries that start in
   water should also be marked as entered at event start if that configuration
   is supported.
6. Accumulate `energyDepositMeV` only for primary-track steps in water.
7. Each PMT sensitive detector collects detected PE count for its PMT ID in
   the event-local `charge[3]` array.
8. PMT IDs outside `0..2` are an error for this fixed output schema.

### Master merge and ROOT output

1. Implement a custom `G4Run` that owns a vector of completed `WCDResult`
   records on each worker.
2. At worker end-of-event, add only results with `enteredWater == true` to its
   worker run.
3. Override `G4Run::Merge()` so worker records are transferred to the master
   run.
4. In master `EndOfRunAction`, sort merged results by internal event ID and
   detector ID, then create `Detector.root` and fill the `Detector` tree.
5. No worker may open, fill, or close the final ROOT file.

This design prevents ROOT write races and produces stable output order.

## WCD Geometry and PMTs

Support one, two, or three PMTs through `numberOfPMTs`.

- One PMT: `(0, 0, +tankHalfHeight)`.
- Two PMTs: `(R, 0, +tankHalfHeight)` and
  `(-R, 0, +tankHalfHeight)`.
- Three PMTs: azimuths `0`, `120`, and `240` degrees at radius `R = D/2`, all
  at `z = +tankHalfHeight`.

Give every PMT a unique copy number and sensitive-detector name. Use the PMT
copy number as its output charge index.

## Configuration

Define and document a standalone configuration format containing at least:

- WCD ID, tank radius, tank height, tank thickness, position, and PMT count.
- PMT model and optical-response parameters.
- Input mode and input file.
- Simulation mode (`full` or fast optical mode).
- Number of worker threads.
- Base random seed.
- ROOT output filename.
- Geometry overlap-check toggle.

Record the complete configuration as a `TNamed` or a small metadata tree in
the ROOT file. This does not change the required `Detector` tree schema.

## CMake Requirements

At minimum:

```cmake
find_package(Geant4 11.2 REQUIRED)
find_package(ROOT 6 REQUIRED COMPONENTS Core RIO Tree)

if(NOT Geant4_multithreaded_FOUND)
  message(FATAL_ERROR "Geant4 must be built with multithreading enabled")
endif()

target_compile_features(G4WCDSimulator PRIVATE cxx_std_17)
target_link_libraries(G4WCDSimulator PRIVATE
  ${Geant4_LIBRARIES}
  ROOT::Core ROOT::RIO ROOT::Tree)
```

Use explicit source lists rather than broad `GLOB` expressions. Keep copied
Meiga attribution/license text where required.

## Verification Plan

1. Build and run a one-PMT WCD with one worker thread.
2. Validate the ROOT file with a small ROOT macro: confirm tree name, branch
   names, types, units, and entry count.
3. Confirm primaries that miss the water volume produce no tree entry.
4. Confirm an entering primary produces primary-only water energy deposit.
5. Confirm absent PMTs write a zero charge.
6. Run two- and three-PMT configurations and verify PMT charge branches map to
   PMT IDs `0`, `1`, and `2`.
7. Compare serial and MT results using the same base seed with one, two, and
   several worker threads. Results must agree event-by-event after sorting.
8. Enable Geant4 overlap checks and resolve or explicitly document geometry
   warnings.
9. Run ThreadSanitizer where the Geant4 build/toolchain supports it.
10. Compare a small serial sample against the current Meiga simulator for
    primary-only energy deposit and PMT charge behavior.

## Delivery Criteria

The project is complete only when it builds independently of Meiga, uses a
multithreaded Geant4 run manager, writes the exact `Detector` tree above on the
master thread, filters non-entering primaries, retains primary-only deposited
energy, and passes the verification plan.
