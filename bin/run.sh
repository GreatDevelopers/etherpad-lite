#!/bin/sh

pecho() { printf %s\\n "$*"; }
log() { pecho "$@"; }
error() { log "ERROR: $@" >&2; }
fatal() { error "$@"; exit 1; }

# Move to the folder where ep-lite is installed
cd "$(dirname "$0")"/..

ignoreRoot=0
for ARG in "$@"; do
  if [ "$ARG" = "--root" ]; then
    ignoreRoot=1
  fi
done

# Stop the script if it's started as root
if [ "$(id -u)" -eq 0 ] && [ "$ignoreRoot" -eq 0 ]; then
  cat <<EOF >&2
You shouldn't start Etherpad as root!
Please type 'Etherpad rocks my socks' (or restart with the '--root'
argument) if you still want to start it as root:
EOF
  printf "> " >&2
  read rocks
  [ "$rocks" = "Etherpad rocks my socks" ] || fatal "Your input was incorrect"
fi

# Prepare the enviroment
#bin/installDeps.sh "$@" || exit 1

# Clear the cache directory so that we can refill it if running outside Sandstorm.
if [ "${SANDSTORM:-no}" = no ]; then
  mkdir -p cache
  # Load .capnp files from sandstorm installation. (In the Sandstorm sandbox, these are mapped
  # to /usr/include.)
  export NODE_PATH="/opt/sandstorm/latest/usr/include"
elif [ ! -e cache ]; then
  echo "ERROR: Must run once outside Sandstorm to populate minification cache" >&2
  exit 1
fi

#Move to the node folder and start
SCRIPTPATH=$(pwd -P)

if [ -e var/dirty.db ]; then
  # Upgrade dirty.db to sqlite.
  echo "Upgrading from dirty.db to sqlite..."
  node $SCRIPTPATH/node_modules/ep_etherpad-lite/sandstorm-migrate.js || exit 1
  gzip -c var/dirty.db > var/dirty-backup.db.gz || exit 1
  rm -f var/dirty.db
  rm -f var/minified_*  # Delete garbage we used to litter here.
fi

log "Started Etherpad..."

exec node "$SCRIPTPATH/node_modules/ep_etherpad-lite/node/server.js" "$@"
