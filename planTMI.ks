//A script which will send a craft towards the Mun by creating a trans-munar-injection
//maneuver, adds it to the flight plan, then terminating.

function main {
  clearscreen.
  doTMI().
}

function doTMI {
  global startSearchTime is ternarySearch(
    angleToMun@,
    time:seconds + 30,
    time:seconds + 30 + orbit:period,
    1
  ).
  
  local transfer is list(startSearchTime, 0).
  set transfer to improveConverge(transfer, munTransferScore@).
  local mnv is node(transfer[0], 0, 0, transfer[1]).
  addManeuverToFlightPlan(mnv).
}

function angleToMun {
  parameter t.
  return vectorAngle(
    Kerbin:position - positionAt(ship, t),
    Kerbin:position - positionAt(Mun, t)
  ).
}

function improveConverge {
  parameter data, scoreFunction.
  for stepSize in list(100, 10, 1, 0.1) {
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

function protectFromPast {
  parameter originalFunction.
  local replacementFunction is {
    parameter data.
    if data[0] < time:seconds + 15 {
      return 2^64.
    } else {
      return originalFunction(data).
    }
  }.
  return replacementFunction@.
}

function munTransferScore {
  parameter data.
  local mnv is node(data[0], 0, 0, data[1]).
  addManeuverToFlightPlan(mnv).
  local result is 0.
  local targetPeriapsis is 35000.
  if mnv:orbit:hasNextPatch {
    set result to abs(mnv:orbit:nextPatch:periapsis - targetPeriapsis)
    + mnv:deltaV:mag.
  } else {
    set result to distanceToMunAtApoapsis(mnv).
  }
  removeManeuverFromFlightPlan(mnv).
  //set result to abs(result + (860 - mnv:dvTotal))
  //print data at (0,2).
  print "munTransferScore: " + round(result) at (0,1).
  //wait 2.
  return result.
}

function ternarySearch {
  parameter f, left, right, absolutePrecision. //f stands for a function delegate
  until false {
    if abs(right - left) < absolutePrecision {
      return (left + right) / 2.
    }
    local leftThird is left + (right - left) / 3.
    local rightThird is right - (right - left) / 3.
    if f(leftThird) < f(rightThird) {
      set left to leftThird. 
    } else {
      set right to rightThird.
    }
  }
}

function distanceToMunAtApoapsis {
  parameter mnv.
  local apoapsisTime is ternarySearch(
    altitudeAt@, 
    time:seconds + mnv:eta,
    time:seconds + mnv:eta + (mnv:orbit:period / 2), 
    1
  ).
  return (positionAt(ship, apoapsisTime) - positionAt(Mun, apoapsisTime)):mag.
}

function altitudeAt {
  parameter t.
  return Kerbin:altitudeOf(positionAt(ship, t)).
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

function removeManeuverFromFlightPlan {
  parameter mnv.
  remove mnv.
}

main().