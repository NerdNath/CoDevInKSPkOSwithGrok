//locks the steering onto a maneuver vector

function main {
  clearscreen.
  sas off.
  print "Press q to end program".

  local keyPress is "".

  until keyPress = "q" {
    if hasnode {
      print "Beginning rotation to burn vector and holding...".
      set myNode to nextnode.
      lockSteeringAtManeuverTarget(myNode).
      until isManeuverComplete(myNode) or keyPress = "q" {
        wait 0.1.
        if terminal:input:haschar {
          set keyPress to terminal:input:getchar().
        }
      }
      if not(keyPress = "q") {
        print "Maneuver was completed".
        print "SAS has been turned on for your convenience!".
        unlock steering.
        SAS on.
        set keyPress to "q".
      }
      if terminal:input:haschar and not(keyPress = "q") {
        set keyPress to terminal:input:getchar().
      }
    } else {
      clearscreen.
      print "No maneuver found. Add a maneuver and then".
      print "run again.".
      set keyPress to "q".
    }
    
    if keyPress = "q" {
      sas on.
    }
  }
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
  if vang(originalVector, mnv:burnvector) >= 90 {
    // Delete originalVector
    declare global originalVector to -1.
    return true.
  }
  return false.
}

main().