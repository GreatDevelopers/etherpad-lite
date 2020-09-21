/**
 * Worker thread to minify JS & CSS files out of the main NodeJS thread
 */

var Terser = require("terser");
var Threads = require('threads')

function compressJS(content)
{
  return Terser.minify(content);
}

Threads.expose({
  compressJS,
})
