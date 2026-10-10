//This script is  used in my Virtuous Destiny KSP playthrough in the first
//program, which I have called the tentative program.
//This is the launch bootloader for the vertical launch pad.

wait until ship:unpacked.
core:part:getmodule("kOSProcessor"):doevent("Open Terminal").

switch to 1.
global scriptName is "autoSubOrb.ks".
copypath("0:/" + scriptName, "").
runOncePath("1:/" + scriptName).