//This is a test space
clearscreen.
//include the needed library scripts for the visual studio code extension
// #include "0:/utilsLibrary/vertLaunchUtils.lib.ks"
// #include "0:/utilsLibrary/orbitalMnvUtils.lib.ks"
// #include "0:/utilsLibrary/vesPtMgmntUtils.lib.ks"

//load the library scripts onto the vessel and run them
if not(core:VOLUME:FILES:HASKEY("library")) {
    createdir("library").
}
if ship:CONNECTION:ISCONNECTED {
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

function testcode1 {
    planMunFRT().
    // TMIfreeReturnAdjust(nextNode).
}

function testcode2 {
    // print "flyby inclination " + nextNode:ORBIT:NEXTPATCH:INCLINATION.
    print "angletoMun: " + angleToMun(nextNode:TIME).
    // print "distance to mun at given time: " + distanceToMunAtTime(nextNode:TIME).
}

function testcode3 {
    planPolarTMI(100000).
}

function testcode4 {
    set target to Mun.
    local shipPos is ship:position - Kerbin:position.
    local munPos is Mun:position - Kerbin:position.
    local shipNorm is vcrs(shipPos, ship:velocity:orbit).
    local munNorm is vcrs(munPos, Mun:velocity:orbit).
    print "Ship normal: " + shipNorm.
    print "Mun normal:  " + munNorm.
    print "Angle between normals: " + vang(shipNorm, munNorm).
}

// testcode1().
// testcode2().
// testcode3().
testcode4().