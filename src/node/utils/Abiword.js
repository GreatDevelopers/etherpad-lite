/**
 * Controls the communication with the Abiword application
 */

/*
 * 2011 Peter 'Pita' Martischka (Primary Technology Ltd)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS-IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
 
var spawn = require('child_process').spawn;
var async = require("async");
var settings = require("./Settings");
var os = require('os');

var doConvertTask;

//on windows we have to spawn a process for each convertion, cause the plugin abicommand doesn't exist on this platform
if(os.type().indexOf("Windows") > -1)
{
  var stdoutBuffer = "";

  doConvertTask = function(task, callback)
  {
    //span an abiword process to perform the conversion
    var abiword = spawn(settings.abiword, ["--to=" + task.destFile, task.srcFile]);
    
    //delegate the processing of stdout to another function
    abiword.stdout.on('data', function (data)
    {
      //add data to buffer
      stdoutBuffer+=data.toString();
    });

    //append error messages to the buffer
    abiword.stderr.on('data', function (data) 
    {
      stdoutBuffer += data.toString();
    });

    //throw exceptions if abiword is dieing
    abiword.on('exit', function (code)
    {
      if(code != 0) {
        return callback("Abiword died with exit code " + code);
      }

      if(stdoutBuffer != "")
      {
        console.log(stdoutBuffer);
      }

      callback();
    });
  };
  
  exports.convertFile = function(srcFile, destFile, type, callback)
  {
    doConvertTask({"srcFile": srcFile, "destFile": destFile, "type": type}, callback);
  };
}
//on unix operating systems, we can start abiword with abicommand and communicate with it via stdin/stdout
//thats much faster, about factor 10
else
{
  //spawn the abiword process
  var abiword;
  var stdoutCallback = null;
  var spawnAbiword = function (){
    abiword = spawn(settings.abiword, ["--plugin", "AbiCommand"]);
    var stdoutBuffer = "";
    var firstPrompt = true;  

    //append error messages to the buffer
    abiword.stderr.on('data', function (data) 
    {
      stdoutBuffer += data.toString();
    });

    //delegate the processing of stdout to a other function
    abiword.stdout.on('data',function (data)
    {
      //add data to buffer
      stdoutBuffer+=data.toString();

      //we're searching for the prompt, cause this means everything we need is in the buffer
      if(firstPrompt) {
        //read and discard through the first prompt
        var promptPos = stdoutBuffer.search("AbiWord:>");
        if (promptPos == -1) {
          //haven't seen first prompt yet
          return;
        }
        firstPrompt = false;
        stdoutBuffer = stdoutBuffer.slice(promptPos + 9);
      }
      if(stdoutBuffer.search("AbiWord:>") != -1)
      {
        //filter the feedback message
        var err = stdoutBuffer.search("OK") != -1 ? null : stdoutBuffer;
        
        //reset the buffer
        stdoutBuffer = "";
        
        //call the callback with the error message
        if(stdoutCallback != null)
        {
          stdoutCallback(err);
          stdoutCallback = null;
        }
      }
    });
  };

  // SANDSTORM EDIT: We don't leave Abiword running, but instead start it up
  //   each time it is needed, because most Etherpad instances won't use it.
  //   (We could make this code a lot cleaner, but we want to keep changes
  //   minimal to avoid future conflicts with upstream.)

  doConvertTask = function(task, callback)
  {
    spawnAbiword();  // SANDSTORM: start new process
    abiword.stdin.write("convert " + task.srcFile + " " + task.destFile + " " + task.type + "\n");
    //create a callback that calls the task callback and the caller callback
    stdoutCallback = function (err)
    {
      abiword.stdin.end();  // SANDSTORM: end the process
      callback();
      console.log("queue continue");
      try{
        task.callback(err);
      }catch(e){
        console.error("Abiword File failed to convert", e);
      }
    };
  };
  
  //Queue with the converts we have to do
  var queue = async.queue(doConvertTask, 1);
  exports.convertFile = function(srcFile, destFile, type, callback)
  {
    queue.push({"srcFile": srcFile, "destFile": destFile, "type": type, "callback": callback});
  };
}
