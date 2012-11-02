#!/bin/bash
########
# this script looks for bios setting files in the current directory, and produces a more human 
# friendly rendition of its content.


for plat in R610 R620 R710 R720 R720xd; do
  for file in `ls *${plat}-*`; do 
     egrep  "(value|attr_name)" $file | awk '
/attr_name/ { name=$2; n=1; next}  /value/ {value=$2; v=1  } v==1 && n==1 { print name "= " value
; n=0; v=0} ' > ${plat}_${file##*$plat}.txt
  done
done

