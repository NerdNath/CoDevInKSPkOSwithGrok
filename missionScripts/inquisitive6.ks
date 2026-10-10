//This is the unique script for the inquisitive 6 vehicle and its mission.

// clearscreen.
//include the needed library scripts
if not(core:VOLUME:FILES:HASKEY("library")) {
    createdir("library").
}
if ship:CONNECTION:ISCONNECTED {
    print "Loading libraries...".
    cd("1:/library").
    copypath("0:/virdestLibrary/vertLaunchUtils.lib.ks","").
    copypath("0:/virdestLibrary/orbitalMnvUtils.lib.ks","").
    print "Initializing libraries contents...".
    list files in libraryList.
    for file in libraryList {
        if file:ISFILE {
            print "running " + file:NAME.
            runOncePath(file).
        }
    }
}

function main {
    clearscreen.
    until false {
        if ship:STATUS = "PRELAUNCH" {
            launchToOrbit().
        }
        else if ship:STATUS = "ORBITING"{
            print "Mission complete. Program terminating.".
            break.
        }
    }
}

function launchToOrbit {
    wait 1.
    dolaunch().//from vertLaunchUtils.lib.ks
    doAscent(   80000,      //Target apoapsis
                0,         //Target heading
                120,         //max pitch drop
                65000,      //scale altitude
                0.8).      //curvature
    doShutdown().//from vertLaunchUtils.lib.ks
    print "ascent complete, coasting to 70km altitude" at (0,10).
    lock steering to prograde.
    wait until ship:STATUS = "SUB_ORBITAL".
    //Jettison nosecone
    lock steering to up.
    wait 5.
    doSafeStage().
    wait 1.
    //circularize orbit
    doCircularization().//from orbitalMnvUtils.lib.ks
}

function doOrbitalMission {
    local numberOfOrbits is MISSIONTIME / ship:ORBIT:PERIOD.
    if floor(numberOfOrbits) >= 2 {
    doSimpleDeorbit(). //from orbitalMnvUtils.lib.ks
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
    lock steering to prograde. //nonintuitive because heatshield on front
    wait until ship:altitude < 15000.
    for part in ship:PARTS {
        if part:NAME = "HeatShield0" {
            part:GETMODULE("ModuleDecouple"):DOEVENT("jettison heat shield").
        }
    }
    wait 2.//allow time for the heat shield to fall away.
    for part in ship:PARTS {
        if part:NAME = "parachuteSingle" {
            part:GETMODULE("ModuleParachute"):DOEVENT("deploy chute").
        }
    }
    unlock steering.
    wait until ship:STATUS = "LANDED".
}

main().