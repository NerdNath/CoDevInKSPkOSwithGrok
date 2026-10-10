// does a circularization the ship's current orbit
// at the current periapsis

function main {
  clearscreen.
  sas off.
  steeringManager:resettodefault().
  doCircularization().
  sas on.
}

function doCircularization {
  local circ is list(time:seconds + eta:apoapsis, 0).
  set circ to improveConverge(circ, eccentricityScore@).
  executeManeuver(list(circ[0], 0, 0, circ[1])).
}

function eccentricityScore {
  parameter data.
  local mnv is node(data[0], 0, 0, data[1]).
  addManeuverToFlightPlan(mnv).
  local result is mnv:orbit:eccentricity.
  removeManeuverFromFlightPlan(mnv).
  return result.
}

function improveConverge {
  parameter data, scoreFunction.
  for stepSize in list(100, 10, 1) {
    until false {
      local oldScore is scoreFunction(data).
      set data to improve(data, stepSize, scoreFunction).
      if oldScore <= scoreFunction(data) {
        break.
      }
    }
  }
  return data.
}

function improve {
  parameter data, stepSize, scoreFunction.
  local scoreToBeat is scoreFunction(data).
  local bestCandidate is data.
  local index is 0.
  local candidates is list().
  until index >= data:length {
    local incCandidate is data:copy().
    local decCandidate is data:copy().
    set incCandidate[index] to incCandidate[index] + stepSize.
    set decCandidate[index] to decCandidate[index] - stepSize.
    candidates:add(incCandidate).
    candidates:add(decCandidate).
    set index to index + 1.
  }
  for candidate in candidates {
    local candidateScore is scoreFunction(candidate).
    if candidateScore < scoreToBeat {
      set scoreToBeat to candidateScore.
      set bestCandidate to candidate.
    }
  }
  return bestCandidate.
}

function addManeuverToFlightPlan {
  parameter mnv.
  add mnv.
}

function calculateStartTime {
  parameter mnv.
  return time:seconds + mnv:eta - maneuverBurntime(mnv) / 2.
}

function maneuverBurntime {
  parameter mnv.
  local dV is mnv:deltaV:mag.
  local g0 is 9.80665.
  local isp is 0.

  list engines in myEngines.
  for en in myEngines {
    if en:ignition and not en:flameout {
      set isp to isp + (en:isp * (en:maxThrust / ship:maxThrust)).
    }
  }

  local mf is ship:mass / constant:e^(dV / (isp*g0)).
  local fuelFlow is ship:maxthrust / (isp * g0).
  local t is (ship:mass -mf) / fuelFlow.

  return t.
}

function lockSteeringAtManeuverTarget {
  parameter mnv.
  lock steering to mnv:burnvector.
}

function isManeuverComplete {
  parameter mnv.
  if not(defined originalVector) or originalVector = -1 {
    declare global originalVector to mnv:burnvector.
  }
  if vang(originalVector, mnv:burnvector) > 90 {
    // Delete originalVector
    declare global originalVector to -1.
    return true.
  }
  return false.
}

function executeManeuver {
  parameter mList.
  local mnv is node(mList[0], mList[1], mList [2], mList[3]).
  addManeuverToFlightPlan(mnv).
  local startTime is calculateStartTime(mnv).
  wait until time:seconds > 10.
  lockSteeringAtManeuverTarget(mnv).
  wait until time:seconds > startTime.
  lock throttle to 1.
  wait until isManeuverComplete(mnv).
  lock throttle to 0.
  unlock steering.
  removeManeuverFromFlightPlan(mnv).
}

function removeManeuverFromFlightPlan {
  parameter mnv.
  remove mnv.
}

main().