//A launch script accumulating the best of my knowledge

function main {
  clearscreen.
  doLaunch().
  doAscent().
  doShutdown().
}

function doLaunch {
  lock steering to up.
  global thrott is 1.
  set throttle to thrott.
  doSafeStage().
}

function doAscent {
  set targetPitch to 90.
  lock targetPitch to getTargetPitch().
  //90 - 0.00274 * alt:radar^0.9562.
  set targetDirection to 90.
  
  until apoapsis > 75000 {
    doAutoStage().
    lock steering to heading(targetDirection, targetPitch).
    lock throttle to thrott.
    lock dThrott to getThrottleBack().
    set thrott to thrott + dThrott.
    wait 0.01.
    print "thrott: " + round(thrott) at (0,5).
    print "target pitch: " + round(targetPitch) at (0,6).
  }
}

function getTargetPitch {
  lock fPitch to 90 - 0.00274 * alt:radar^0.9562.
  if fPitch >= 0 {
    return fPitch.
  }
  else {
    return 0.
  }
}

function getThrottleBack {
  set g to kerbin:mu / kerbin:radius^2.
  lock accvec to ship:sensors:acc - ship:sensors:grav.
  lock gForce to accvec:mag / g.
  return 0.05 * (1.5 - gForce).
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
}

main().