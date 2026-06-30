# Water-Cherenkov Detector Simulation Workspace

This repository contains a Geant4/ROOT workflow for simulating water-Cherenkov detectors (WCDs), comparing the standalone implementation against Meiga reference code, and analysing PMT charge spectra from the produced ROOT files.

The main executable lives in `G4WCDStandalone/`. It reads a JSON simulation configuration, an XML detector description, and a particle input file, then produces a ROOT tree with one row per primary event that enters a WCD water volume. The `analysis/` directory contains Python/ROOT tools for producing PMT charge histograms grouped by particle type.

## Repository layout

```text
.
├── Dockerfile                  # Reproducible Ubuntu + Geant4 + ROOT environment
├── G4WCDStandalone/            # Standalone C++17 Geant4 WCD simulator
│   ├── CMakeLists.txt
│   ├── config/                 # Example simulation JSON, detector XML, and native inputs
│   ├── include/                # Simulator headers
│   ├── src/                    # Simulator implementation
│   ├── tests/                  # C++ validation tests and small example inputs
│   └── README.md               # Component-level simulator notes
├── analysis/                   # PyROOT analysis scripts and generated plots
│   ├── plot_pmt_charges.py     # Full grouped PMT charge analysis
│   └── plot_pmt_charges_fit.py # Optional fit-oriented charge plotting helper
└── meiga/                      # Local Meiga reference source used for comparisons
```

## What the standalone simulator does

`G4WCDStandalone` models cylindrical water-Cherenkov detectors with up to three XP1805-like PMTs. The current implementation includes:

- Geant4 multithreaded batch simulation.
- ROOT output written only by the Geant4 master thread after worker results are merged.
- ARTI/CORSIKA-style input support and native PDG input support.
- CORSIKA-to-PDG conversion for common particles and nuclei.
- Water optical properties, liner optical surfaces, PMT quantum-efficiency response, and PMT charge counters.
- Full and fast optical modes:
  - `full`: optical photons are transported to the PMTs, where QE/collection response is sampled.
  - `fast`: optical photons may be killed at creation according to PMT response.
- Per-event counters for total WCD water energy deposit, Cherenkov photons, PMT photon impacts, and PMT charge.
- A configurable soil slab under the WCD array that stops particles after they cross below the detectors.
- Optional VRML visualization through Geant4 (`g4_00.wrl`, `g4_01.wrl`, ...).

## Dependencies

Native builds require:

- CMake 3.20 or newer
- A C++17 compiler
- Geant4 11.2+ built with multithreading enabled
- ROOT 6 with Python bindings for the analysis scripts
- Python 3 for analysis utilities

The provided `Dockerfile` builds a suitable environment with Geant4 and ROOT installed under `/opt`.

## Option A: use Docker

Build the image:

```bash
docker build -t g4wcd-env .
```

Run a shell with this repository mounted:

```bash
docker run --rm -it -v "$PWD":/work g4wcd-env
```

Inside the container, Geant4 and ROOT environment scripts are sourced by the entrypoint. You can build and run directly from `/work`.

## Option B: native environment setup

If Geant4 and ROOT are already installed, load their environment scripts before configuring the project. The exact paths depend on your installation; for the Docker image they are:

```bash
source /opt/geant4/bin/geant4.sh
source /opt/root/bin/thisroot.sh
```

Then check that CMake can find both packages:

```bash
cmake --version
root-config --version
```

## Build the standalone simulator

From the repository root:

```bash
cmake -S G4WCDStandalone -B G4WCDStandalone/build
cmake --build G4WCDStandalone/build -j2
```

The executable is created at:

```text
G4WCDStandalone/build/G4WCDSimulator
```

Run the focused validation tests:

```bash
ctest --test-dir G4WCDStandalone/build --output-on-failure
```

If your local `G4WCDStandalone/config/simulation.json` is being used for ad-hoc runs, the `wcd_config` test may fail when that file no longer matches the test expectation. The simulator and ROOT validation tests can be run selectively:

```bash
ctest --test-dir G4WCDStandalone/build \
  -R "wcd_pmt_response|wcd_run_single|wcd_run_mt|wcd_root_validation" \
  --output-on-failure
```

## Configure a simulation

The main configuration file is JSON. A typical file looks like:

```json
{
  "Input": {
    "Mode": "UseARTI",
    "File": "tanca_test.shw"
  },
  "Simulation": {
    "Mode": "fast",
    "Threads": 20,
    "BaseSeed": 123456789,
    "CheckOverlaps": true,
    "GeoVisOn": false,
    "TrajVisOn": false,
    "PhysicsList": "QGSP_BERT_HP"
  },
  "Output": {
    "RootFile": "tanca_test.root"
  },
  "DetectorList": "detector.xml",
  "PMT": {
    "Model": "XP1805",
    "CollectionEfficiency": 0.7
  }
}
```

Important fields:

- `Input.Mode`
  - `UseARTI` or `arti`: CORSIKA/ARTI-style rows.
  - `native` or `pdg`: direct PDG rows.
- `Input.File`: particle input file. Relative paths are resolved from the JSON file location when needed.
- `Simulation.Mode`
  - `full`: transport optical photons to PMTs.
  - `fast`: sample PMT response earlier and kill rejected optical photons.
- `Simulation.Threads`: number of Geant4 worker threads.
- `Simulation.GeoVisOn`: write geometry VRML scene.
- `Simulation.TrajVisOn`: store and render trajectories in VRML output.
- `Output.RootFile`: output ROOT file name.
- `DetectorList`: XML detector description.
- `PMT.CollectionEfficiency`: collection efficiency multiplier applied to the PMT quantum-efficiency curve.

## Configure the detector

Detector geometry is described in XML, for example:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<detectorList>
  <soil size="5" unit="m"/>
  <injectionMode type="eCircle">
    <radius unit="m">2.76</radius>
    <height unit="m">1.21</height>
  </injectionMode>

  <detector id="0" type="WCD">
    <position unit="m" x="0.0" y="0.0" z="0.0"/>
    <tank radius="1.8" height="1.2" thickness="0.02" unit="m"/>
    <numberOfPMTs>3</numberOfPMTs>
    <pmtRadialDistance unit="m">1.2</pmtRadialDistance>
  </detector>
</detectorList>
```

Key points:

- `soil` creates one slab below the WCD array. The default side length is 5 m if omitted. The slab is 10 cm thick and stops tracks that enter it.
- `tank.height` is the water cylinder height.
- `tank.thickness` is the external liner thickness.
- `pmtRadialDistance` sets the radial placement of PMTs for multi-PMT tanks.
- Multiple WCDs can be described by adding more `<detector>` blocks. They must share a common base elevation for the single soil slab.

### Injection modes

`<injectionMode>` can be:

- `eFromFile`: use each input row’s `x y z` position.
- `eCircle`: sample positions uniformly on a disk above the WCD.
- `eHalfSphere`: sample positions on a half-spherical surface.
- `eVertical`: inject from a fixed point or disk with vertical momentum from the input.

For `eCircle`, `height` is interpreted relative to the WCD reference geometry so that, for a 1.20 m tank with 2 cm liner, `height=1.21 m` places the source plane 1 cm above the external lid.

## Particle input formats

### Native PDG mode

Use `Input.Mode = "native"` and rows of the form:

```text
# pdg px py pz x y z
13 0 0 -5 0 0 0.63
```

Units:

- momentum: GeV/c
- position: m

### ARTI/CORSIKA mode

Use `Input.Mode = "UseARTI"` and rows of the form:

```text
CorsikaId px py pz x y z shower_id prm_id prm_energy prm_theta prm_phi
```

The simulator converts CORSIKA particle IDs to PDG IDs before passing particles to Geant4. Coordinates from ARTI-style input are converted from cm to m, and the vertical momentum sign is adjusted to match the standalone simulation convention.

## Run examples

Run from the repository root using a config file in `G4WCDStandalone/config`:

```bash
cd G4WCDStandalone/build
./G4WCDSimulator ../config/simulation.json
```

Run a simple native vertical muon configuration after preparing a matching JSON:

```bash
cd G4WCDStandalone/build
./G4WCDSimulator ../config/simulation_vertical_muon.json
```

The output ROOT file is written according to `Output.RootFile`. If the JSON says:

```json
"Output": { "RootFile": "vertical_muon_5gev.root" }
```

then the output file is created in the current working directory from which the executable is launched.

## ROOT output

The output file contains:

- `Detector`: a `TTree` with one entry per event/detector crossing.
- `Configuration`: a `TNamed` object containing the simulation and detector configuration text.

Current tree branches include:

```text
partId
DetectorId
px, py, pz
x, y, z
energy_deposit
cherenkov_photons
pmt_0_impacts, pmt_1_impacts, pmt_2_impacts
charge_pmt_0, charge_pmt_1, charge_pmt_2
```

`energy_deposit` is the total energy deposited in WCD water by all tracks, including secondaries, for that event and detector. `charge_pmt_*` is the PMT charge in photoelectrons.

ROOT writing is performed only in the Geant4 master thread after worker results are merged. The file is explicitly created, checked, written, and closed.

## Visualization

Set either of these in the JSON config:

```json
"GeoVisOn": true,
"TrajVisOn": true
```

The simulator uses the Geant4 VRML2FILE driver. Typical outputs are:

```text
g4_00.wrl
g4_01.wrl
g4_02.wrl
...
```

The first file is generally the initialized geometry scene. Later files can contain trajectories when `TrajVisOn` is enabled. In full optical mode, stored trajectories can include Cherenkov optical photons. In fast mode, photons rejected by the fast PMT response are killed and cannot appear in trajectory output.

You can view WRL files with a VRML viewer such as `view3dscene`:

```bash
view3dscene G4WCDStandalone/build/g4_01.wrl
```

## Analyse PMT charge spectra

The main analysis script is:

```text
analysis/plot_pmt_charges.py
```

Run the full grouped analysis:

```bash
python3 analysis/plot_pmt_charges.py \
  G4WCDStandalone/build/tanca_test.root \
  --output-dir analysis/output
```

The script builds four particle groups in one pass over the ROOT tree:

- electromagnetic: `e-`, `e+`, `gamma`
- muons: `mu-`, `mu+`
- neutrons: `neutron`, `anti-neutron`
- all particles

It writes:

- one overlay canvas per PMT with all four groups;
- one single-group canvas per PMT and group;
- one ROOT file containing all histograms.

Example outputs:

```text
analysis/output/charge_pmt_0_groups.png
analysis/output/charge_pmt_1_groups.png
analysis/output/charge_pmt_2_groups.png
analysis/output/charge_pmt_0_muons.png
analysis/output/charge_pmt_0_electromagnetic.png
analysis/output/charge_pmt_0_neutrons.png
analysis/output/charge_pmt_0_all.png
analysis/output/pmt_charge_histograms.root
```

Useful options:

```bash
# More bins
python3 analysis/plot_pmt_charges.py G4WCDStandalone/build/tanca_test.root --bins 200

# Change the visible charge range; default is 600 PE
python3 analysis/plot_pmt_charges.py G4WCDStandalone/build/tanca_test.root --x-max 250

# Skip PNG rendering and only write ROOT histograms
python3 analysis/plot_pmt_charges.py G4WCDStandalone/build/tanca_test.root --no-png
```

If ROOT cannot render PNG files because an image backend library is missing, the histogram ROOT file is still written.

## Development notes

- Build products, ROOT files, WRL files, analysis PNGs, and local caches are ignored by the root `.gitignore`.
- Keep source, tests, configuration templates, and documentation under version control.
- Large simulation inputs and ROOT outputs should generally stay outside Git or be managed with a dedicated data-storage workflow.
- The `meiga/` tree is kept as reference material for comparing physics, geometry, optical properties, and visualization behavior.

## Quick command summary

```bash
# Build
cmake -S G4WCDStandalone -B G4WCDStandalone/build
cmake --build G4WCDStandalone/build -j2

# Test
ctest --test-dir G4WCDStandalone/build --output-on-failure

# Run
cd G4WCDStandalone/build
./G4WCDSimulator ../config/simulation.json
cd ../..

# Analyse
python3 analysis/plot_pmt_charges.py \
  G4WCDStandalone/build/tanca_test.root \
  --output-dir analysis/output
```
