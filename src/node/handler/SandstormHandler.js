var ERR = require("async-stacktrace");
var authorManager = require("../db/AuthorManager");
var Capnp = require("capnp");
var SandstormHttpBridge = Capnp.importSystem("sandstorm/sandstorm-http-bridge.capnp").SandstormHttpBridge;

var capnpConnection = null;
var httpBridge = null;

function getHttpBridge() {
  if (!httpBridge) {
    capnpConnection = Capnp.connect("unix:/tmp/sandstorm-api");
    httpBridge = capnpConnection.restore(null, SandstormHttpBridge);
  }
  return httpBridge;
}

var lastActivityTime = {};

var ACTIVITY_TYPES = {
  "edit": 0,
  "comment": 1,
  "reply": 2,
};

exports.activity = function (sessionId, type, path, threadPath, threadTitle) {
  if (type == "edit") {
    // Only post edits once every 15 seconds per active session.
    var last = lastActivityTime[sessionId] || 0;
    var now = Date.now();
    if (now - last < 15000) return;
    lastActivityTime[sessionId] = now;
  }

  Promise.resolve().then(() => {
    var httpBridge = getHttpBridge();
    var activity = {};
    
    if (type) {
      activity.type = ACTIVITY_TYPES[type];
    }
    
    if (path) {
      activity.path = path;
    }

    if (threadPath) {
      activity.thread = {
        path: threadPath,
        title: { defaultText: threadTitle || threadPath },
      };
    }

    return httpBridge.getSessionContext(sessionId).context.activity(activity);
  }).catch(err => {
    console.error(err.stack);
  });
}

