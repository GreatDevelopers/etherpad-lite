#! /bin/bash

for file in cache/*.js%3F*; do
  if [ ${file%.gz} != $file ]; then continue; fi
  if [ ${file%.ugly} != $file ]; then continue; fi
  if grep -q already_ugly $file; then continue; fi
  
  echo $file
  uglify -s $file -o $file.ugly
  echo "//already_ugly" >> $file.ugly
  mv $file.ugly $file
  rm -f $file.gz
  gzip -k $file
done

for file in cache/*.css; do
  if [ ${file%.gz} != $file ]; then continue; fi
  if [ ${file%.ugly} != $file ]; then continue; fi
  if grep -q already_ugly $file; then continue; fi
  
  echo $file
  cleancss -o $file.ugly $file
  echo "/*already_ugly*/" >> $file.ugly
  mv $file.ugly $file
  rm -f $file.gz
  gzip -k $file
done

