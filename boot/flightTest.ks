//This script is  used in my Virtuous Destiny KSP playthrough in the parts
//testing program.
//This is the launch bootloader for the vertical launch pad.

wait until ship:unpacked.
core:part:getmodule("kOSProcessor"):doevent("Open Terminal").

switch to 1.
global scriptName is "tentativeTestbed.ks".
global pathString is "missionScripts/".
copypath("0:/" + pathString + scriptName, "").
runOncePath("1:/" + scriptName).