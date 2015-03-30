#!/bin/bash
#Stuff-01!
h=$(hostname | awk '{if ($1=="frontend") {print 0} else if ($1=="hernan") {print 5} else {print $0}}' | sed -e 's/halley0//')
home=${PWD}

#similar flux separation, using 3 branchs
mkdir ${home}/f1
mkdir ${home}/f2
mkdir ${home}/f3

for i in 001206 001608 000703 002412 001105 002814 001407 002010 005626 000904 003216 002713 002311 004020 001909 005224 004018 004822 005525 003919 005123 003115 003517 004521; do
  mv -v DAT${i}.bz2 ${home}/f1
done

for j in $(seq 1 4); do
  printf -v n %02d $j
  i=0${j}0402 
  mv -v DAT${i}.bz2 ${home}/f1
done

for j in $(seq 1 8); do
  printf -v n %02d $j
  i=${n}0014
  mv -v DAT${i}.bz2 ${home}/f1
done

for j in $(seq 9 20); do
  printf -v n %02d $j
  i=${n}0014
  mv -v DAT${i}.bz2 ${home}/f2
done

for j in $(seq 21 32); do
  printf -v n %02d $j
  i=${n}0014
  mv -v DAT${i}.bz2 ${home}/f3
done

# analisys
for k in $(seq 1 3); do
  file=f${k}
  echo "cd ${home}/f${k}
for i in DAT??????.bz2; do
  j=\$(echo \$i | sed -e 's/.bz2//')
  u=\$(echo \$j | sed -e 's/DAT//');
  bzip2 -v -d -k \$i
  echo \$j | lagocrkread | analysis -v \$u
  rm \$j
done
cd ${home}/
rm f${k}.sh" > f${k}.sh
  chmod 744 f${k}.sh
  screen -d -m -a -S flux-${k} ${home}/f${k}.sh 
  screen -ls
done
