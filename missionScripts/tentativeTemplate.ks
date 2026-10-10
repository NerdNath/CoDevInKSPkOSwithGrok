//This is the template script for inquisitive vehicles and their missions.

// clearscreen.
//include the needed library scripts
if not(core:VOLUME:FILES:HASKEY("library")) {
    createdir("library").
}
if ship:CONNECTION:ISCONNECTED {
    print "Loading libraries...".
    local libSourceDir is "virdestLibrary/".
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

function main {
    until false {
        if ship:STATUS = "PRELAUNCH" {
            launchSuborbital().
        }
        else if ship:STATUS = "ORBITING"{
            print "In orbital mission phase.".
            doOrbitalMission(2).
        }
        else if ship:STATUS = "SUB_ORBITAL" or ship:STATUS = "FLYING" {
            print "In reEntry and Landing mission phase.".
            doReEntryAndLanding().
        }
        else if ship:STATUS = "LANDED" or ship:STATUS = "SPLASHED" {
            print "Mission appears to be complete. Program terminating.".
        }
    }
}

function launchSuborbital {
    wait 10.
    dolaunch().//from vertLaunchUtils.lib.ks
    doAscent(   15000,      //Target apoapsis
                90,         //Target heading
                50,         //max pitch drop
                1000,      //scale altitude
                2).      //curvature
    doShutdown().//from vertLaunchUtils.lib.ks
    print "ascent complete, coasting to apoapsis".
    lock steering to prograde.
    wait time:SECONDS + ship:ORBIT:ETA:APOAPSIS.
}

// function launchToOrbit {
//     wait 10.
//     dolaunch().//from vertLaunchUtils.lib.ks
//     doAscent(   15000,      //Target apoapsis
//                 90,         //Target heading
//                 50,         //max pitch drop
//                 1000,      //scale altitude
//                 2).      //curvature
//     doShutdown().//from vertLaunchUtils.lib.ks
//     print "ascent complete, coasting to 70km altitude" at (0,10).
//     lock steering to prograde.
//     wait until ship:STATUS = "SUB_ORBITAL".
//     //Jettison nosecone
//     lock steering to up.
//     wait 5.
//     doSafeStage().
//     wait 1.
//     //circularize orbit
//     doCircularization().//from orbitalMnvUtils.lib.ks
// }

function doOrbitalMission {
    parameter desiredOrbits.
    local numberOfOrbits is MISSIONTIME / ship:ORBIT:PERIOD.
    if floor(numberOfOrbits) >= desiredOrbits {
        doCollisionDeorbit(). //from orbitalMnvUtils.lib.ks
        doSafeStage(). //expected to release the second stage
        print "Waiting until atmospheric entry begins.".
        wait until ship:STATUS = "FLYING".
    }
    else {
        print "Waiting until 2 orbits are completed.".
        wait until floor(MISSIONTIME / ship:ORBIT:PERIOD) >= 2.
    }
}

function doReEntryAndLanding {
    // print "holding steering on prograde because heatshield is on the front".
    lock steering to retrograde.
    wait until ship:altitude < 15000.
    print "deploying chute".
    attemptEventOnTagged("main chute", "deploy chute").//from vesPtMgmtUtils
    unlock steering.
    wait until ship:STATUS = "LANDED" or ship:STATUS = "SPLASHED".
}

main().