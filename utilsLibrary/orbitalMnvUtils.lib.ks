//This library contains functions useful in making orbital maneuvers

//include the needed library scripts for the visual studio code extension

// #include "0:/utilsLibrary/helperReqsUtils.lib.ks"

//load the library scripts onto the vessel and run them
if not(core:VOLUME:FILES:HASKEY("library")) {
    createdir("library").
}
if ship:CONNECTION:ISCONNECTED {
  copyPath("0:/utilsLibrary/helperReqsUtils.lib.ks","1:/library").
  local loadedPath is "1:/library/helperReqsUtils.lib.ks".
  runOncePath(loadedPath).
}
switch to 1.

//Takes the ships current orbit, plans then executes a maneuver to make it
//circular
function doCircularization {
  print "Planning circularization maneuver".
  local circ is list(time:seconds + eta:apoapsis, 0).
  set circ to improveConverge(circ, eccentricityScore@).
  executeManeuver(list(circ[0], 0, 0, circ[1])).
}

//Takes the ships current orbit, plans then executes a maneuver at the apoapsis
//to make the periapsis collide with the parent body. The purpose to dorbit the
//vessel.
function doCollisionDeorbit {
  print "Planning deorbit maneuver".
  local rDv is list(0).//retrograde deltaV
  local myStepSizes is list(100, 10, 1, 0.1, 0.01, 0.001, 0.0001).
  set rDv to improveConverge(rDv, collisionScore@, myStepSizes).
  print "collision score: " + collisionScore(rDv).
  executeManeuver(list(time:SECONDS + eta:APOAPSIS, 0, 0, rDv[0])).
}

//Takes a list of two scalars (whole numbers), where the first is a universal
//time, and the second is deltaV in the prograde direction, and returns
//the eccentricity of the current vessel's orbit after that maneuver
function eccentricityScore {
  parameter data.
  local mnv is node(data[0], 0, 0, data[1]).
  addManeuverToFlightPlan(mnv).
  local result is mnv:orbit:eccentricity.
  removeManeuverFromFlightPlan(mnv).
  return result.
}

//Takes a scalar (number) of deltaV in the prograde direction, and returns
//the inverse of the periapsis of the current vessel's orbit after that maneuver
//unless the periapsis becomes negative, at which point it will always return 1.
//The intent and purpose is to return a good score if the maneuver results in
//a collision course with the parent body
function collisionScore {
  parameter data.
  local mnv is node(time:SECONDS + eta:APOAPSIS, 0, 0, data[0]).
  addManeuverToFlightPlan(mnv).
  local result is mnv:ORBIT:APOAPSIS.
  if mnv:ORBIT:PERIAPSIS < -50 {
    set result to abs(mnv:ORBIT:PERIAPSIS).
  }
  else {
    set result to mnv:ORBIT:PERIAPSIS.
  }
  removeManeuverFromFlightPlan(mnv).
  return result.
}

//What:Basically this function just loops the data and the scoreFunction through
//the improve() function indefinitely until improve() can't make it better
//How:Takes a parameter, runs that parameter through a score function, and then
//runs through the improve() function, compares the results of those two
//until improve() doesn't make a difference anymore
// function improveConverge {
//   parameter data, scoreFunction.
//   parameter stepSizeList is list(100, 10, 1, 0.1).
//   for stepSize in stepSizeList {
//     until false {
//       local oldScore is scoreFunction(data).
//       set data to improve(data, stepSize, scoreFunction).
//       if oldScore <= scoreFunction(data) {
//         break.
//       }
//     }
//   }
//   return data.
// }

function improveConverge {
    parameter data, scoreFunction.
    parameter stepSizeList is list(100, 10, 1, 0.1).

    for stepSize in stepSizeList {
        print "=== Starting step size: " + stepSize at (0,15).
        local iterations is 0.
        
        until false {
            local oldScore is scoreFunction(data).
            print "Step " + stepSize + " | Old score: " + oldScore at (0,16).
            
            set data to improve(data, stepSize, scoreFunction).
            
            local newScore is scoreFunction(data).
            print "Step " + stepSize + " | New score: " + newScore at (0,17).
            
            set iterations to iterations + 1.
            if iterations > 50 { 
                print "Too many iterations at step " + stepSize. 
                break. 
            }
            
            if newScore >= oldScore - 0.001 {   // small tolerance
                print "No improvement at step " + stepSize.
                break.
            }
        }
    }
    return data.
}

//Uses a hillclimbing approach to take some data, a stepsize, and scoreFunction
//gets a score from 1)the data, 2)the data incremented by the stepsize, and 
//3) the data decremented from the stepsize. Then it returns the one with
//the best score
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

//the function does what the name describes. Exists for code readability
//https://ksp-kos.github.io/KOS_DOC/structures/vessels/node.html#ADD
function addManeuverToFlightPlan {
  parameter mnv.
  add mnv.
}

//this function takes a maneuver object, and returns the exact time to start
//that maneuver so that the burn time will be split in half evenly across the
//instantaneous time of the maneuver. Returns false if maneuverBurntime() does.
//A function calling this one must handle a boolean return in order to avoid
//scripts terminatingn with an error.
function calculateStartTime {
  parameter mnv.
  local mnvDuration is maneuverBurntime(mnv).
  if mnvDuration:ISTYPE("Scalar") {
    return time:seconds + mnv:eta - mnvDuration / 2.
  }
  else {
    return false.
  }
}

//this function looks at the current vessel, and returns how long it will take
//to execute the manuever with its current engines that have been ignited, and
//do not have the flameout state. If there are no engines in that condition,
//this function returns false, which must be handled anywhere it is called.
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

  if isp > 0 {
    local mf is ship:mass / constant:e^(dV / (isp*g0)).
    local fuelFlow is ship:maxthrust / (isp * g0).
    local t is (ship:mass -mf) / fuelFlow.
    return t.
  }
  else {
    return false.
  }
}

//this function does what the name describes. Exists for code readability
//https://ksp-kos.github.io/KOS_DOC/structures/vessels/node.html#structure:MANEUVERNODE
function lockSteeringAtManeuverTarget {
  parameter mnv.
  lock steering to mnv:burnvector.
}

//This function monitors the burn vector of a maneuver, and returns true if
//that burn vector flips 90 degrees. It works on the assumption that it is an
//indicator that the maneuver was completed
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
  else if ship:STAGEDELTAV(ship:STAGENUM):CURRENT = 0 {
    print "No fuel available in the current stage. Ending maneuver execution".
    return true.
  }
  return false.
}

//this function does what the name describes. Utilizes multiple other utilities.
//If no ignited engine without the flamed out status is available on the vessel
//at the time this function is run, it will end without performing the maneuver
//and print a message explaining the issue.
//Warning: can be quite imprecise with vehicles that have extremely high or low
//thrust to weight ratios
function executeManeuver {
  parameter mList.
  local mnv is node(mList[0], mList[1], mList [2], mList[3]).
  local startTime is time:SECONDS.
  If not hasNode {
    addManeuverToFlightPlan(mnv).
    set startTime to calculateStartTime(mnv).
  }
  else {
    set startTime to calculateStartTime(nextNode).
  }
  wait until time:seconds > 10.
  lockSteeringAtManeuverTarget(nextNode).
  //check if useable engine is available
  if startTime:ISTYPE("Scalar") {
    print "waiting until maneuver start time".
    wait until time:seconds > startTime.
    lock throttle to 1.
    wait until isManeuverComplete(nextNode).
    lock throttle to 0.
    unlock steering.
    removeManeuverFromFlightPlan(nextNode).
  }
  else {
    print "No engine appears to be available. Cannot execute maneuver".
    unlock steering.
  }
}

//This function does what the name describes. Exists for code readability
//https://ksp-kos.github.io/KOS_DOC/structures/vessels/node.html#global:REMOVE
function removeManeuverFromFlightPlan {
  parameter mnv.
  remove mnv.
}

//This function performs a very rudimentary and low awareness attempt at
//deorbiting a ship that is in low orbit. It simply locks the steering to
//retrograde, throttles up until there's no more fuel, and then ends.
function doSimpleDeorbit {
  lock steering to retrograde.
  until ship:AVAILABLETHRUST = 0 {
    lock throttle to 1.
  }
  unlock steering.
  lock throttle to 0.
}

//takes a time, and returns the angle of the vessel to the mun at that time
function angleToMun {
  parameter t.
  return vectorAngle(
    Kerbin:position - positionAt(ship, t),
    Kerbin:position - positionAt(Mun, t)
  ).
}

//Takes a function delegate (pointer to a function), a left bounds value,
//and a right bounds value, each as a scalar, and an absolute precision
//value. It checks whether the absolute precision fits between the bounds
//and returns the value right in the middle between the bounds if it does
//not. Then it takes the edge thirds of the range between the bounds,
//compares them via the function delegate, then trims the section off that
//has the worst result. It repeats this until the bounds is less than the
//precision, then returns the result
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

//takes a time value as a parameter, and returns the altitude over kerbin
//of the current vessel at that time in its predicted flight path
function kerbinAltitudeAt {
  parameter t.
  return Kerbin:ALTITUDEOF(positionAt(ship, t)).
}

//takes a maneuver node object as a parameter, calculates and returns the
//distance that the current vessel will be from the mun when it is at the
//apoapsis of the orbit that will result from that maneuver. The function
//is intended for when the current vessel is in orbit around kerbin.
function distanceToMunAtApoapsis {
  parameter mnv.
  local apoapsisTime is ternarySearch(
    kerbinAltitudeAt@, 
    time:seconds + mnv:eta,
    time:seconds + mnv:eta + (mnv:orbit:period / 2), 
    1
  ).
  return (positionAt(ship, apoapsisTime) - positionAt(Mun, apoapsisTime)):mag.
}

function distanceToMunAtTime {
  parameter gTime. //the given time
  return (positionAt(ship, gTime) - positionAt(Mun, gTime)):mag.
}

//This function is intended for when the current vessel is in orbit
//around kerbin. It takes in a list of data values as a parameter
//(ie. a time and deltaV) then calculates and returns a score based on
//how close the ship will be to either the mun at kerbin orbit apoapsis,
//or to a 35km periapsis of the mun if a next patch exists
function munTransferScore {
  parameter targetPeriapsis is 1156000.
  parameter data is list(time:SECONDS + ship:ORBIT:PERIOD, 860).
  local mnv is node(data[0], 0, 0, data[1]).
  addManeuverToFlightPlan(mnv).
  local result is 0.
  if mnv:orbit:hasNextPatch {
    set result to abs(mnv:orbit:nextPatch:periapsis - targetPeriapsis)
    + mnv:deltaV:mag.
  } else {
    set result to distanceToMunAtApoapsis(mnv).
  }
  removeManeuverFromFlightPlan(mnv).
  //set result to abs(result + (860 - mnv:dvTotal))
  //print data at (0,2).
  // print "munTransferScore: " + round(result) at (0,1).
  //wait 2.
  return result.
}

//makes a maneuver that will put the current vessel on a trajectory to
//fly by the mun with a 35km closest approach. Intended to be run when in
//an orbit around Kerbin
function planTMI {
  parameter desiredApproachDistance is 60000.
  local startSearchTime is ternarySearch(
    angleToMun@,
    time:seconds + 30,
    time:seconds + 30 + orbit:PERIOD,
    1
  ).

  local mnvInputs is list(startSearchTime, 860).
  local scoreFunctionDelegate is munTransferScore@:BIND(desiredApproachDistance).
  set mnvInputs to improveConverge(mnvInputs, scoreFunctionDelegate).
  local mnv is node(mnvInputs[0], 0, 0, mnvInputs[1]).
  addManeuverToFlightPlan(mnv).
}

//WIP function that will take a maneuver as a parameter, check if it produces
//a transmunar injection, and if it does, adjust that maneuver until it will 
//provide a free return trajectory from that transmunar injection. Relies on
//multiple orbit patches, and therefore requires upgraded tracking station
function TMIfreeReturnAdjust {
  //provided node, target mun periapsis, target kerbin periapsis
  parameter pN, tgtMunPeri is 35000, tgtKerbinPeri is 32000.

  require(pN:ISTYPE("Node"), "TMIfreeReturnAdjust given wrong parameter type").
  require(ship:BODY = Kerbin, "TMIfreeReturnAdjust called not in kerbin orbit").
  require(ship:STATUS = "ORBITING", "Not in orbit + TMIfreeReturnAdjust called").
  local mnvInputs is list(pN:TIME,pN:PROGRADE).
  local scoreFunctionDelegate is frtScore@:BIND(tgtMunPeri,tgtKerbinPeri).
  removeManeuverFromFlightPlan(pN).
  local mySteps is list(1, 0.1, 0.01, 0.001).
  set mnvInputs to improveConverge(mnvInputs, scoreFunctionDelegate, mySteps).
  local mnv is node(mnvInputs[0], 0, 0, mnvInputs[1]).
  addManeuverToFlightPlan(mnv).
}

function frtScore {
  parameter tgtMunPeri is 35000, tgtKerbinPeri is 32000.
  parameter mnvData is list(time:SECONDS + ship:ORBIT:PERIOD, 867).
  local mnv is node(mnvData[0], 0, 0, mnvData[1]).
  local result is 0.
  addManeuverToFlightPlan(mnv).
  if mnv:ORBIT:HASNEXTPATCH {
    if mnv:ORBIT:NEXTPATCH:BODY = MUN {
      local munScore is abs(mnv:ORBIT:NEXTPATCH:PERIAPSIS - tgtMunPeri).
      local postFlybyObt is mnv:ORBIT:NEXTPATCH:NEXTPATCH.
      if postFlybyObt:HASNEXTPATCH {return KERBIN:SOIRADIUS.}
      local kerbinScore is abs(postFlybyObt:PERIAPSIS - tgtKerbinPeri).
      set result to munScore + kerbinScore.
    }
    else {set result to KERBIN:SOIRADIUS.}
  }
  else {set result to distanceToMunAtApoapsis(mnv).}
  removeManeuverFromFlightPlan(mnv).
  return result.
}

function planMunFRT {
  parameter tgtMunPeri is 35000, tgtKerbinPeri is 32000.

  local mnvTime is list(time:SECONDS + 30).
  set mnvTime to improveConverge(mnvTime, frtStartScore@).
  local mnv is node(mnvTime[0], 0, 0, 870.1).
  addManeuverToFlightPlan(mnv).
  if not(mnv:ORBIT:HASNEXTPATCH) {
    removeManeuverFromFlightPlan(mnv).
    set mnvTime[0] to mnvTime[0] + 2580. //previous time plus 43 min
    set mnvTime to improveConverge(mnvTime, frtStartScore@).
    set mnv to node(mnvTime[0], 0, 0, 870.1).
    addManeuverToFlightPlan(mnv).
  }
  local mnvInputs is list(mnvTime[0],870.1).
  local scoreFunctionDelegate is frtScore@:BIND(tgtMunPeri,tgtKerbinPeri).
  removeManeuverFromFlightPlan(mnv).
  local mySteps is list(1, 0.1, 0.01, 0.001).
  set mnvInputs to improveConverge(mnvInputs, scoreFunctionDelegate, mySteps).
  set mnv to node(mnvInputs[0], 0, 0, mnvInputs[1]).
  addManeuverToFlightPlan(mnv).
}

function frtStartScore {
  parameter t.
  return abs(angleToMun(t[0]) - 120).
}

function nextPatchEncountersMun {
  parameter pOrbit. //provided orbit
  if pOrbit:HASNEXTPATCH {
    if pOrbit:NEXTPATCH:BODY = MUN {return true.}
  }
  else {return false.}
}

function planMunImpact {
  local bestTime is findBestTMI(35000, 32000).
  local mnvP is list(0).
  local stepSizes is list(100, 10, 1, 0.1, 0.01, 0.001).
  set mnvP to improveConverge(mnvP, apoMunAltScore@, stepSizes).
  local mnv is node(bestTime, 0, 0, mnvP[0]).
  addManeuverToFlightPlan(mnv).
}

//returns the absolute value of the difference between the provided orbit's
//apoapsis and the altitude of the mun
function apoMunAltScore {
  parameter pData. //provided prograde deltaV
  local mnv is node(time:SECONDS + 30, 0, 0, pData[0]).
  addManeuverToFlightPlan(mnv).
  local result is abs(MUN:ALTITUDE - mnv:OBT:APOAPSIS).
  removeManeuverFromFlightPlan(mnv).
  print "apoMunAltScore: " + result at(0, 12).
  return result.
}

//finds the best TMI time
function findBestTMI {
    parameter targetMunPe.
    parameter targetKerbinPe.

    local candidates is list().
    local t is time:seconds + 60.   // start searching soon

    for i in range(0, 5) {   // look for up to 5 candidates
        local bestTime is findNextAngleTime(t, 120.3, t + 6*3600).

        if bestTime > 0 {
            local score is evaluateTMIScore(bestTime, targetMunPe, targetKerbinPe).
            candidates:add( lexicon("time", bestTime, "score", score) ).
            set t to bestTime + 35*60.   // jump forward ~half orbit
        }
    }

    if candidates:length = 0 {
        print "No valid TMI found.".
        return -1.
    }

    // Pick best
    local best is candidates[0].
    for c in candidates {
        if c:score < best:score {
            set best to c.
        }
    }

    print "Best TMI at " + (best:time - time:seconds) + " seconds from now.".
    return best:time.
}

// Finds next time where angleToMun is close to targetAngle
function findNextAngleTime {
    parameter startTime, targetAngle, maxTime.

    local t is ternarySearchForAngle(startTime, targetAngle, maxTime).
    if t <= 0 or t > maxTime {
        return -1.
    }
    return t.
}

// Evaluates how good a TMI time is
function evaluateTMIScore {
    parameter t, targetMunPe, targetKerbinPe.

    local mnv is node(t, 0, 0, 870).
    add mnv.
    wait 0.

    local score is 0.

    // Mun flyby quality
    local munPe is mnv:orbit:periapsis.
    set score to score + abs(munPe - targetMunPe) * 15.

    // Post-flyby Kerbin Pe - safely check for next patch
    local hasNextPatch is false.
    if mnv:orbit:hasnextpatch {
        local nextP is mnv:orbit:nextpatch.
        if nextP:body = kerbin {
            set score to score + abs(nextP:periapsis - targetKerbinPe).
            set hasNextPatch to true.
        }
    }

    if not(hasNextPatch) {
        set score to score + 1e9.   // huge penalty
    }

    remove mnv.
    return score.
}

// Ternary search for angle (minimize |angle - target|)
function ternarySearchForAngle {
    parameter left, targetAngle, right.

    for i in range(0, 80) {   // safety limit
        if abs(right - left) < 1 {
            return (left + right) / 2.
        }

        local leftThird is left + (right - left) / 3.
        local rightThird is right - (right - left) / 3.

        local leftVal is abs(angleToMun(leftThird) - targetAngle).
        local rightVal is abs(angleToMun(rightThird) - targetAngle).

        if leftVal < rightVal {
            set right to rightThird.
        } else {
            set left to leftThird.
        }
    }
    return (left + right) / 2.
}

function polarTMIscore {
    parameter tgtMunPe.
    parameter pData.   // [prograde, normal, radial]

    local mnv is node(time:seconds + 30, pData[2], pData[1], pData[0]).
    add mnv.
    wait 0.

    local score is 0.

    // 1. Mun flyby altitude
    local munPe is mnv:orbit:periapsis.
    set score to score + abs(munPe - tgtMunPe) * 10.

    // 2. Inclination at Mun flyby (safe check)
    local flybyInc is 0.
    if mnv:orbit:hasnextpatch {
        local nextP is mnv:orbit:nextpatch.
        if nextP:body = mun {
            set flybyInc to nextP:inclination.
        } else {
            set score to score + 1e9.
        }
    } else {
        set score to score + 1e9.
    }

    set score to score + abs(flybyInc - 90) * 20.

    remove mnv.
    return score.
}

function planPolarTMI {
    parameter targetMunPe.          // e.g. 35000

    local bestTime is findBestTMI(targetMunPe, 0).   // Kerbin Pe doesn't matter much

    // Start with [prograde, normal, radial]
    local burnVector is list(870, 0, 0).

    local stepSizes is list(100, 10, 1, 0.1, 0.01).

    local scoreFDel is polarTMIscore@:BIND(targetMunPe).//FDel=functionDelegate
    set burnVector to improveConverge(burnVector, scoreFDel, stepSizes).

    local mnv is node(bestTime, burnVector[2], burnVector[1], burnVector[0]).
    addManeuverToFlightPlan(mnv).
}