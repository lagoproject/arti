# G4WCDStandalone

Standalone Geant4 simulation of water Cherenkov detectors. It is being
extracted from Meiga as an independent C++17 project with Geant4 MT and ROOT
output.

## Status

The executable implements an MT Geant4 batch simulation. Worker threads keep
event data private; results are merged into a custom `G4Run` and the ROOT file
is written only by the Geant4 master thread.

## Dependencies

- CMake 3.20+
- C++17 compiler
- Geant4 11.2+ built with multithreading enabled
- ROOT 6 (`Core`, `RIO`, and `Tree`)

## Configure

```sh
cmake -S . -B build
cmake --build build
./build/G4WCDSimulator config/simulation.json
```

The configure step intentionally fails when Geant4 lacks multithreading
support.

## Soil volume

Every detector configuration creates one `Soil` slab under the WCD array. It is 10 cm thick and stops any track immediately when it enters the slab. The default horizontal size is 5 m × 5 m. Change its square side in `detector.xml` with:

```xml
<soil size="5" unit="m"/>
```

`size` is the horizontal side length and accepts `m`, `cm`, or `mm`; the slab is centred on the WCD-array footprint. All WCDs must share the same bottom elevation and fit within the configured side length. For example, use `<soil size="8" unit="m"/>` for an 8 m × 8 m slab.

## Visualization

The `Simulation` object accepts Meiga-compatible `GeoVisOn` and `TrajVisOn`
boolean options, both `false` by default. Setting either option to `true`
creates a VRML render file (`g4_00.wrl`) in the working directory. `GeoVisOn`
renders the detector geometry; `TrajVisOn` also stores and renders particle
trajectories.


## Injection mode

`detector.xml` accepts Meiga-compatible injection settings through an optional
`<injectionMode>` element. The supported values are `eCircle`, `eHalfSphere`,
`eVertical`, and `eFromFile` (the default when the element is omitted).
Coordinates and lengths accept `m`, `cm`, or `mm`; angles are in degrees.

```xml
<injectionMode type="eCircle">
  <x unit="m">0</x><y unit="m">0</y><z unit="m">0</z>
  <radius unit="m">1.5</radius>
  <height unit="m">2</height>
  <minPhi>0</minPhi><maxPhi>360</maxPhi>
</injectionMode>
```

`eCircle` samples uniformly over the disk above the external WCD lid. Its `height` is compared with the configured tank height: for a 1.20 m tank with 2 cm liner thickness, `height=1.21 m` produces a source plane at `z=0.63 m`, i.e. 1 cm above the external lid; `eHalfSphere` samples
uniformly over the selected spherical surface angles; `eVertical` samples a
disk (or the fixed origin for radius zero); and `eFromFile` retains each input
row’s `x y z` position.

## Layout

- `config/`: standalone simulation and detector configuration examples
- `include/`, `src/`: standalone implementation
- `third_party/meiga-baseline/`: unmodified reference files copied from Meiga;
  these are not compiled or linked
- `tests/`, `macros/`: validation code and ROOT inspection macros

## Primary input

The configured input file is a whitespace-delimited text file. Blank lines and
lines beginning with `#` are ignored. Each remaining line has:

```
pdg px py pz x y z
```

Momentum is in GeV/c and the injection position is in metres. One line maps to
one Geant4 event. The output tree contains only events whose primary track
crosses into a WCD water volume. `energy_deposit` is the primary-track water
energy deposit in MeV. PMT charge is simulated in both full and fast optical modes; the fixed
schema always writes zero for absent PMTs or no detected photoelectrons.
