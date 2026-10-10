//this will take a vessel in freefall and execute a suicide burn touchdown

function main {
  clearscreen.
  doHoverslam().
}

function doHoverslam {
  
  sas off.
  lock steering to srfRetrograde.
  print "Steering locked on surface retrograde." at (0,1).
  lock pct to stoppingDistance() / distanceToGround().
  print "Stopping distance: " + stoppingDistance() at (0,2).
  wait until pct > 1.
  //lock throttle to abs(pct).
  lock throttle to pct.
  print "Landing burn start..." at (0,3).
  when distanceToGround() < 500 then { gear on. }
  print "Gear out..." at (0,4).
  wait until ship:verticalSpeed > 0.
  lock throttle to 0.
  print "Landing burn complete..." at (0,5).
  //lock steering to R(groundSlope():X, groundSlope():Y, srfRetrograde:ROLL).
  set NAVMODE to "SURFACE".
  set SASMODE to "STABILITYASSIST".
  unlock steering.
  sas on.
  print "SAS turned on to stabilize".
  //print "Holding Ship onto ground slope vector..." at (0,6).
  //wait 30.
  //unlock steering.
  print "Steering unlocked." at (0,7).
}

function distanceToGround {
  local boundsBox is ship:bounds.
  return round(boundsBox:BOTTOMALTRADAR, 1).
  
  
  //return altitude - body:geopositionOf(ship:position):terrainHeight - 4.7.
}

function stoppingDistance {
  local grav is constant():g * (body:mass / body:radius^2).
  local maxDeceleration is (ship:availableThrust / ship:mass) - grav.
  return ship:verticalSpeed^2 / (2 * maxDeceleration).
}

function groundSlope {
  local east is vectorCrossProduct(north:vector, up:vector).

  local center is ship:position.

  local a is body:geopositionOf(center + 5 * north:vector).
  local b is body:geopositionOf(center - 3 * north:vector + 4 * east).
  local c is body:geopositionOf(center - 3 * north:vector - 4 * east).

  local a_vec is a:altitudePosition(a:terrainHeight).
  local b_vec is b:altitudePosition(b:terrainHeight).
  local c_vec is c:altitudePosition(c:terrainHeight).

  return vectorCrossProduct(c_vec - a_vec, b_vec - a_vec):normalized.
}

main().