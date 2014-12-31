t=0
for i in DAT??????.bz2; do
#  t=$((($t+1)%2))
  j=$(echo $i | sed -e 's/.bz2//')
  u=$(echo $j | sed -e 's/DAT//')
#  if [ $t -eq 0 ]; then 
    bzip2 -d -v -k $i
    echo $j | lagocrkread | analysis -p -v $u
#  else
#    bzip2 -d -v -k $i || echo $j | lagocrkread | analysis -p -v $u &
#  fi
  rm $j
done
