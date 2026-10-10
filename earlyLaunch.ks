//A launch script for early game ascents


clearscreen.
doLaunch().
doAscent().
doShutdown().

function doLaunch {
  lock steering to up.
  global thrott is 1.
  set throttle to thrott.
  doSafeStage().
}

function doAscent {
  set targetPitch to 90.
  lock targetPitch to getTargetPitch().
  //Minmus inclination north: 83.67
  set nMinInc to 83.67.
  //Minmus inclination south: 96.33
  set sMinInc to 96.33.
  set targetDirection to 180.
  set targetApoapsis to 115000.
  print "targetDirection: " + targetDirection at (0,1).
  print "targetApoapsis: " + targetApoapsis at (0,2).

  until apoapsis > targetApoapsis {
    doAutoStage().
    lock steering to heading(targetDirection, targetPitch).
    wait 0.1.
    print "target pitch: " + targetPitch at (0,3).
  }
}

function getTargetPitch {
  //  *** first example gravity turn curve: 90 - 0.00274 * alt:radar^0.9562 ***
  // use wolframalpha.com
  // prompt: plot 90 - 0.00274 * y^0.9562
  // cheerskevin example: 88.963 - 1.03287 * y^0.409511
  // this equation in form p - v * y^c
  // seems to have the "v" value affect the altitude where zero pitch is acheived
  // while the "c" value seems to affect the curve rate of the pitchover
  lock fPitch to round(90 - 0.00244 * alt:radar^0.95, 1).
  if fPitch >= 0 {
    return fPitch.
  }
  else {
    return 0.
  }
}

function doAutoStage {
  if not(defined oldThrust) {
    declare global oldThrust to ship:availableThrust.
  }
  if ship:availableThrust < (oldThrust - 10) {
    doSafeStage. wait 1.
    set oldThrust to ship:availableThrust.
  }
}

function doSafeStage {
  wait until stage:ready.
  stage.
}

function doShutdown {
  lock throttle to 0.
  unlock steering.
  clearscreen.
}