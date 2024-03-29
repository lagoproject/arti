# WCD Simulation

## How to Run

1. Compile the code, from build directory:
  
```bash
cmake -DGeant4_DIR=/path/geant4.10.3-install/lib/Geant4-10.3.0/ path-code
make -jN // Where N number of cores
```

2. Edit input.in file:

   * /spectrum/readfile "file name" > ARTI `.shw.bz2` file containing the secondaries at ground.

   * /spectrum/iniposZ "X cm" > Start position at Z from which secondaries will propagate.
    This value can not be more than 45 m.

   * /spectrum/radArea "X m" > The circumference radius where secondaries will be distribute.
    This value can not be more than 45 m.

   * /detect/radio > WCD radius.

   * /detect/hight > WCD height. This value can not be more than 4.5 m

   * /outroot/outname > Set the name for the Root output filie. 

   * /run/beamOn "X" > Number of secondaries to propagate.
   
   If you need values bigger than 45 m or 4.5 cm please [contact us](https://github.com/lagoproject/arti#Contact)

3. Execute:

```bash
./wcd -m input.in > run.log 
```

4. Remember, the data is saved in the `.root` file `histosOutput.root`.

## How to read `histosOutput.root`

1. Check the histograms names from TBrowser.

2. Go to directory `readOutRootFile`

3. Open `main.cxx` and change the `histo` name according to the information
   that you desire. Be carefull with the number of bins for histogram,
   check in the TBrowser.

4. Then, compile and excecute: 

```bash
make clean
make
./mainExe histosOutput.root > out.dat
```

6. Plotting.
