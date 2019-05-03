# lagoDetector

# ===================
# *** How to Run: ***

1. Compile the code, from build directory:
  cmake -DGeant4_DIR=/path/geant4.10.3-install/lib/Geant4-10.3.0/ path-code
  make -jN // Where N number of cores

2. Edit input.in file:
   - /spectrum/readfile "file name" > Corsika .shw file with the secondaries.
   - /spectrum/iniposZ "X cm" > Start position at Z from which secondaries will propagate. 
    This value can not be more than 45 m.
   - /spectrum/radArea "X m" > The circumference radius where secondaries will be distribute. 
    This value can not be more than 45 m.
   - /detect/radio > WCD radius.
   - /detect/hight > WCD hight. This value can not be more than 4.5 m
   - /run/beamOn "X" > Number of secondaries to propagate.
   
   If you need values bigger than 45 m or 4.5 cm write to mauricio.suarez@saber.uis.edu.co

2. Execute:
  ./lago -m input.in > kk.dat 

3. Remember, the data is saved in the Root file histosOutput.root

# =====================================
# *** How to read histosOutput.root ***

1. Check the histograms names from TBrowser.

2. Go to directory readOutRootFile

3. Open main.cxx and change the histo name according to the information
   that you desire. Be carefull with the number of bins for histogram,
   check in the TBrowser. 

4. make clean; make

5. ./mainExe histosOutput.root > out.dat

6. Plotting.

