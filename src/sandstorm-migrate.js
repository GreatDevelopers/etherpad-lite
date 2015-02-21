// The first releases of Etherpad on Sandstorm unfortunately used dirty.db as
// the database, because it at first appeared like a perfectly cromulent way to
// store data for a single-document, single-process instance. Unfortunately, I
// missed the fact that dirty.db is append-only, and as a result etherpad
// documents have tended to get very large over time, as the same text is
// repeatedly stored to the database over and over.
//
// So now we're switching to sqlite, which we should have done in the first
// place. But we need to migrate old pads. So that's where this script comes
// in.

var ueberDB = require("ueberDB");
var dirtyDB = require("ueberDB/node_modules/dirty");

var dirty = new dirtyDB("var/dirty.db");
var sqlite = new ueberDB.database("sqlite", {filename: "var/sqlite3.db"});

var dirtyLoaded = false;
var dirtyCount;
dirty.on("load", function (count) {
  dirtyCount = count;
  dirtyLoaded = true;
});
dirty.on("error", function (err) {
  console.error(err);
  process.exit(1);
});

function sqliteInitialized(err) {
  if (err) {
    console.error(err);
    process.exit(1);
  }

  if (dirtyLoaded) {
    dirtyInitialized(dirtyCount);
  } else {
    dirty.on("load", dirtyInitialized);
  }
}

function dirtyInitialized(count) {
  dirty.forEach(function (key, val) {
    sqlite.set(key, val);
  });
  
  sqlite.doShutdown(done);
}

function done(err) {
  if (err) {
    console.error(err);
    process.exit(1);
  }

  sqlite.close(closed);
}

function closed(err) {
  if (err) {
    console.error(err);
    process.exit(1);
  }
  
  process.exit(0);
}

sqlite.init(sqliteInitialized);

