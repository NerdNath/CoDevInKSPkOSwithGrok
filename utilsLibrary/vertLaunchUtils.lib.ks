//This library contains functions used in vertical launches of rockets

//global variable declarations to avoid false warnings by the kOS language
//server from the Visual Studio Code extension
declare global oldThrust to 0.

//Very simple takeoff function
function doLaunch {
    lock steering to up.
    global thrott is 1.
    lock throttle to thrott.
    doSafeStage().
}

//performs a vertical ascent with a gravity turn or other pitchover, roll,
//yaw, or inclination adjustment
function doAscent {
  parameter targetApoapsis is 75000.//in meters
  parameter targetDirection is 90. //this is a heading
  parameter maxPitchDrop is 82. //next 3 are for passing on to getTargetPitch
  parameter scaleAltitude is 65000.
  parameter curv is 0.85.
  parameter apoapsisAdvancement is 40.//will affect when throttleback occurs
  clearscreen.
  // global targetPitch is 90.
  lock targetPitch to getTargetPitch(maxPitchDrop,scaleAltitude,curv).
  //Minmus inclination north: 83.67
  // local nMinInc is 83.67.
  //Minmus inclination south: 96.33
  // local sMinInc is 96.33.
  print "targetDirection: " + targetDirection at (0,1).
  print "targetApoapsis: " + targetApoapsis at (0,2).

  until apoapsis > targetApoapsis {
    doAutoStage().
    jettMainFairing().
    if ship:DELTAV:CURRENT = 0 {
      print "No fuel available on vessel. Concluding the ascent.".
      break.
    }
    lock steering to heading(targetDirection, targetPitch).
    if targetPitch > 1 and ship:ALTITUDE < 60000 {
      print "throttle setting: " + round(getApoapsisEtaThrottleSet(),2) at (0, 12).
      lock throttle to getApoapsisEtaThrottleSet(apoapsisAdvancement).
    }
    else {
      print "throttle setting: " + 1 at (0, 12).
      lock throttle to 1.
    }
    wait 0.1.
    print "target pitch: " + targetPitch at (0,3).
  }
}

function getTargetPitch {
  parameter maxPitchDrop is 82. //how many degrees the turn is allowed to go
  parameter scaleAltitude is 65000.//the altitude the curve is centered around
  parameter curv is 0.85.//how much the curve curves. 1 is linear,
  //between 0 and 1 turns early, flattens later, greater than 1 stays vertical,
  //then turns later
  lock fPitch to round(90 - maxPitchDrop*(alt:radar/scaleAltitude)^curv,2).
  //The following logic prevents target pitch from going below 0
  if fPitch >= 0 {
    return fPitch.
  }
  else {
    return 0.
  }
}

function getApoapsisEtaThrottleSet {
  parameter etaLimit is 40.
  local throttleSetting is 1.
  set etaActual to ship:ORBIT:ETA:APOAPSIS.
  if etaActual > 0 {
    set throttleSetting to min(1.0, etaLimit / etaActual).
    return throttleSetting.
  }
  else {
    return 1.0.
  }
}

//wip that returns a throttle setting value that will not exceed a
//desired dynamic pressure limit
function getQLimitingThrottleSetting {
  parameter qLimit is 10.
  local throttleSetting is 1.
  lock qActual to ship:DYNAMICPRESSURE * constant:AtmToKpa.
  if qActual > 0 {
    set throttleSetting to min(1.0, qLimit / qActual).
    return throttleSetting.
  }
  else {
    return 1.0.
  }
}

//performs the operations determining what pitch vehicle should go to and hold
function DEPRECATEDgetTargetPitch {
  //  *** first example gravity turn curve: 90 - 0.00274 * alt:radar^0.9562 ***
  // use wolframalpha.com
  // prompt: plot 90 - 0.00274 * y^0.9562
  // cheerskevin example: 88.963 - 1.03287 * y^0.409511
  // this equation in form p - v * y^c
  // seems to have the "v" value affect the altitude where zero pitch is acheived
  // while the "c" value seems to affect the curve rate of the pitchover
  lock fPitch to round(90 - 0.00244 * alt:radar^0.929, 1).
  if fPitch >= 0 {
    return fPitch.
  }
  else {
    return 0.
  }
}

//calculates how much the ship should throttle back during ascent.
function getThrottleBack {
  set g to kerbin:mu / kerbin:radius^2.
  lock accvec to ship:sensors:acc - ship:sensors:grav.
  print "accvec:mag: " + accvec:mag at (0,6).
  lock gForce to accvec:mag / g.
  print "gForce: " + gForce at (0,7).
  print "throttleBack value:" + 0.05 * (1.5 - gForce) at (0,8).
  return 0.05 * (1.5 - gForce).
}

//when run in a loop, function will monitor for a change in available thrust
//roughly consistent with an engine shutting off from depletion of fuel
function doAutoStage {
  if oldThrust = 0 {
    set  oldThrust to ship:availableThrust.
  }
  print "oldThrust: " + oldThrust at (0,4).
  print "available Thrust: " + ship:availablethrust at (0,5).
  if ship:availableThrust < (oldThrust - 7) {
    doSafeStage. wait 1.
    set oldThrust to ship:availableThrust.
  }
}

//ensures it is possible to fire off a stage, then does so
function doSafeStage {
  wait until stage:ready.
  stage.
}

//performs a shutdown proceedure intended for the end of an ascent
function doShutdown {
  lock throttle to 0.
  unlock steering.
  clearscreen.
}

function jettMainFairing {
  parameter jettisonAlt is 55000.
  if ship:ALTITUDE > jettisonAlt {
    if ship:PARTSTAGGED("main fairing"):LENGTH > 0 {
      local fairingPart is ship:PARTSTAGGED("main fairing")[0].
      if fairingPart:GETMODULE("ModuleProceduralFairing"):HASEVENT("deploy") {
        fairingPart:GETMODULE("ModuleProceduralFairing"):DOEVENT("deploy").
      }
    }
  }
}