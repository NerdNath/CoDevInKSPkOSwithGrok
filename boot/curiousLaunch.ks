//This script is  used in my Virtuous Destiny KSP playthrough in the third
//program, which I have called the curious program.
//This is the launch bootloader for the vertical launch pad.

wait until ship:unpacked.
core:part:getmodule("kOSProcessor"):doevent("Open Terminal").

switch to 1.
global scriptName is "curious9.ks".
global scriptDir is "missionScripts/".
if core:VOLUME:FILES:HASKEY(scriptName) {
    runOncePath("1:/" + scriptName).
}
else if homeConnection:ISCONNECTED {
    copypath("0:/" + scriptDir + scriptName, "").
    runOncePath("1:/" + scriptName).
}
else {
    print "Waiting for connection to the archive...".
    wait until homeConnection:ISCONNECTED.
    print "Connection obtained. Loading script".
    copypath("0:/" + scriptDir + scriptName, "").
    runOncePath("1:/" + scriptName).
}