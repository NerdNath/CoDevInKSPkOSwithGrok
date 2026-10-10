//This is the unique script for the curious 8 vehicle and its mission

//include the needed library scripts for the visual studio code extension
// #include "0:/utilsLibrary/vertLaunchUtils.lib.ks"
// #include "0:/utilsLibrary/orbitalMnvUtils.lib.ks"
// #include "0:/utilsLibrary/vesPtMgmntUtils.lib.ks"
// #include "0:/utilsLibrary/missionManUtils.lib.ks"

//load the library scripts onto the vessel and run them
if not(core:VOLUME:FILES:HASKEY("library")) {
    createdir("library").
}
if homeConnection:ISCONNECTED {
    print "Loading libraries...".
    local libSourceDir is "utilsLibrary/".
    local neededLibaries is list(
        "vertLaunchUtils.lib.ks",
        "orbitalMnvUtils.lib.ks",
        "vesPtMgmntUtils.lib.ks"
    ).
    cd("1:/library").
    for lib in neededLibaries {
        print "copying " + lib.
        copyPath("0:/" + libSourceDir + lib,"").
    }
    print "Initializing libraries contents...".
    list files in libraryList.
    for file in libraryList {
        if file:ISFILE {
            print "running " + file:NAME.
            runOncePath(file).
        }
    }
}
switch to 1.

function main{
    until false {
        if ship:STATUS = "PRELAUNCH" {
            launchToOrbit().
            deployAntenna().
        }
        else if ship:STATUS = "ORBITING"
        and ship:BODY:NAME = "Kerbin"
        and ship:ORBIT:APOAPSIS < 90000 {
            print "In low kerbin orbit mission phase.".
            deployAntenna().
            startMaterialStudy().
            if hasNode {
                print "tmi is already in the flight plan".
                print "executing trans munar injection".
                executeTransMunarInjection().
                set munSOIEncounterEta to time:SECONDS + ship:ORBIT:NEXTPATCHETA.
                print "munSOIEncounterEta: " + munSOIEncounterEta.
            }
            else {
                print "Planning transmunar injection maneuver".
                planTransMunarInjection().
            }
        }
        else if ship:ORBIT:HASNEXTPATCH
        and ship:BODY:NAME = "Kerbin"
        and MISSIONTIME < 20000 {
            print "In coast to Mun encounter phase: ".
            doCoastPhase().
        }
        else if ship:BODY:NAME = "Mun"
        and ship:STATUS = "ESCAPING" {
            print "In munar flyby mission:".
            performMunarFlybyMission().
        }
        else if ship:BODY:NAME = "Kerbin"
        and ship:STATUS = "Escaping" {
            lock steering to retrograde.
            print "preventing escape from kerbin".
            until ship:STATUS = "ORBITING" {
                lock throttle to 0.2.
            }
            lock throttle to 0.
        }
        else if ship:STATUS = "ORBITING" or ship:STATUS = "SUB_ORBITAL"
        and ship:BODY:NAME = "Kerbin"
        and ship:ORBIT:APOAPSIS >= 90000
        and MISSIONTIME > 35000 {
            print "In return mission phase:".
            doReturnMission().
        }
        else if ship:STATUS = "FLYING"{
            print "In reEntry and landing mission phase:".
            doReEntryAndLanding().
        }
        else if ship:STATUS = "LANDED" or ship:STATUS = "SPLASHED" {
            wait 3.
            print "Mission appears to be complete. Program terminating".
            break.
        }
    }
}

function launchToOrbit {
    dolaunch().//from vertLaunchUtils.lib.ks
    doAscent(   80000,      //Target apoapsis
                90,         //Target heading
                130,        //max pitch drop
                70000,      //scale altitude
                1.1,        //curvature
                40).        //eta apoapsis target
    doShutdown().//from vertLaunchUtils.lib.ks
    print "ascent complete, coasting to 70km altitude" at (0,10).
    lock steering to prograde.
    wait until ship:STATUS = "SUB_ORBITAL".
    //circularize orbit
    print "circularizing orbit...".
    doCircularization().//from orbitalMnvUtils.lib.ks
}

function deployAntenna {
    print "deploying antenna".
    attemptEventOnTagged("main transmitter", "extend antenna").
}

function startMaterialStudy {
    print "starting material study".
    local eventName is "<b>materials study</b>: <color=#ffd200>stopped</color>".
    attemptEventOnTagged("main science jr", eventName).
}

function startMysteryGoo {
    print "starting mystery goo observation".
    local s is "<b>mystery goo™ observation</b>: <color=#ffd200>stopped</color>".
    attemptEventOnTagged("main goo", s).
}

function planTransMunarInjection {
    print "planning trans munar injection.".
    planTMI(35000).//from orbitalMnvUtils.lib.ks
}

function executeTransMunarInjection {
    set myNode to list(nextNode:TIME, 0, 0, nextNode:PROGRADE).
    print "entering maneuver execution program".
    executeManeuver(myNode).//from orbitalMnvUtils.lib.ks
    print "trans munar injection program complete.".
}

function doCoastPhase {
    wait until ship:BODY = "Mun".
}

function performMunarFlybyMission {
    if ship:VERTICALSPEED < 0 and ship:ALTITUDE > 60000 {
        print "waiting until ship enters mun space low".
        wait until ship:ALTITUDE < 60000.
        startMysteryGoo().
    }
    else {
        print "waiting until ship escapes the mun".
        wait until ship:BODY:NAME = "Kerbin".
    }
}

function doReturnMission{
    // until MISSIONTIME > ship:ORBIT:PERIOD {
    //     print "Completing 1 orbit around kerbin to avoid second mun encounter".
    //     wait until MISSIONTIME > ship:ORBIT:PERIOD.
    // }
    if ship:STATUS = "ORBITING" {
        print "planning and executing a deorbit burn at apoapsis".
        if hasNode = true {
            until hasNode = false {remove nextNode.}
        }
        doCollisionDeorbit().
        lock steering to up.
        wait 3.
        print "Jettisoning 2nd stage...".
        doSafeStage(). //from vertLaunchUtils.lib.ks
    }
    wait 1.
    lock steering to retrograde.
    print "waiting for reentry interface to begin".
    wait until ship:STATUS = "FLYING".
}

function doReEntryAndLanding{
    lock steering to retrograde.
    print "retracting antenna...".
    attemptEventOnTagged("main transmitter", "retract antenna").//from vsPtMngm
    wait until ship:ALTITUDE < 15000.
    print "deploying parachute...".
    wait 1.
    attemptEventOnTagged("main chute", "deploy chute").
    wait until ship:STATUS = "LANDED" or ship:STATUS = "SPLASHED".
    print "Touchdown...".
}

main().