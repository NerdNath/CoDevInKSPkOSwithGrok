// completes the next maneuver in the flight plan

function main {
  clearscreen.
  steeringManager:resettodefault().
  sas off.
  print "Press q to end program".
  print "".

  global keyPress is "".
  if hasnode {
    set myNode to nextnode.
    executeManeuver(myNode).
  } else {
    clearscreen.
    print "No maneuver found. Add a maneuver and then".
    print "run again.".
    set keyPress to "q".
  }

  if keyPress = "q" {
    clearscreen.
    sas on.
  }
}

function executeManeuver {
  parameter mnv.
  local startTime is calculateStartTime(mnv).
  //wait until time:seconds > 10.
  if not(keyPress = "q") {
    print "Beginning rotation to burn vector and waiting".
    print "until moment of maneuver".
    lockSteeringAtManeuverTarget(mnv).
    until time:seconds > startTime or keyPress = "q" {
      wait 0.1.
      if terminal:input:haschar {
        set keyPress to terminal:input:getchar().
      }
    }
    if not(keyPress = "q") {
      print "Executing burn...".
      lock throttle to 1.
    }
    until isManeuverComplete(mnv) or keyPress = "q" {
      wait 0.1.
      if terminal:input:haschar {
        set keyPress to terminal:input:getchar().
      }
    }
    if not(keyPress = "q") {
      print "Burn end".
      lock throttle to 0.
      unlock steering.
      print "Steering unlocked".
      print "".
    }
    print "Maneuver complete!".
    print "".
    print "SAS has been turned on for your convenience".
  }
}

function calculateStartTime {
  parameter mnv.
  return time:seconds + mnv:eta - maneuverBurnTime(mnv) / 2.
}

function maneuverBurnTime {
  parameter mnv.
  local dV is mnv:deltaV:mag.
  local g0 is 9.80665.
  local isp is 0.

  list engines in myEngines.
  for en in myEngines {
    if en:ignition and not en:flameout {
      set isp to isp + (en:isp * (en:availableThrust / ship:availableThrust)).
    }
  }

  local mf is ship:mass / constant():e^(dV / (isp*g0)).
  local fuelFlow is ship:availableThrust / (isp * g0).
  local t is (ship:mass -mf) / fuelFlow.

  return t.
}

function lockSteeringAtManeuverTarget {
  parameter mnv.
  lock steering to mnv:burnvector.
  if terminal:input:haschar {
    //set keyPress to terminal:input:getchar().
    clearscreen.
  }
}

function isManeuverComplete {
  parameter mnv.
  if not(defined originalVector) or originalVector = -1 {
    declare global originalVector to mnv:burnvector.
  }
  if vang(originalVector, mnv:burnvector) > 90 {
    // Delete originalVector
    declare global originalVector to -1.
    sas on.
    return true.
  }
  return false.
}

main().