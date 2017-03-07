#! /bin/bash

set -euo pipefail

minify_embeds() {
  # TODO(someday): Minify JS too. But require-kernel.js seems to be concocted from thin air.
  local pattern='^Ace2Editor\.EMBEDED\["\.\./([^"]*\.css)"] = '
  while read -r LINE; do
    if [[ "$LINE" =~ $pattern ]]; then
      embed=${BASH_REMATCH[1]}
      echo -n "Ace2Editor.EMBEDED[\"../$embed\"] = \""
      cleancss src/$embed | sed -e 's/"/\\"/g'
      echo "\";"
    else
      echo "$LINE"
    fi
  done
}

for file in cache/*.js%3F*; do
  if [ ${file%.gz} != $file ]; then continue; fi
  if [ ${file%.ugly} != $file ]; then continue; fi
  if grep -q already_ugly $file; then continue; fi

  echo "**** $file" >&2
  
  if egrep -q '^Ace2Editor\.EMBEDED\["\.\./([^"]*\.css)"] = ' $file; then
    echo "* minifying embeds too" >&2
    minify_embeds < $file > $file.reembed
    mv $file.reembed $file
  fi

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

  echo "**** $file" >&2

  if grep -q "@import url([\"']./" $file; then
    sed -i -re "s,@import url\(([\"'])\./,@import url(\1../src/static/css/,g" $file
  fi

  echo $file
  cleancss -o $file.ugly $file
  echo "/*already_ugly*/" >> $file.ugly
  mv $file.ugly $file
  rm -f $file.gz
  gzip -k $file
done

