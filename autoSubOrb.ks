//This script assumes that the craft is at the launch pad and is a rocket
//it will silently (without prompting) launch the vessel, ascend to the specified
//apoapsis, and then terminate. It is intended for suborbital flight and contains no
//specific method for reaching a stable orbit

clearscreen.
//include the needed library scripts
if not(core:VOLUME:FILES:HASKEY("library")) {
    createdir("1:/library").
}
if ship:CONNECTION:ISCONNECTED {
    print "Loading libraries...".
    cd("1:/library").
    copypath("0:/virdestLibrary/vertLaunchUtils.lib.ks","").
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
    // clearScreen.
    dolaunch().//from vertLaunchUtils.lib.ks
    doAscent(   66000,      //Target apoapsis
               90,         //Target heading
                0,         //max pitch drop
                2000,      //scale altitude
                1.95).      //curvature
    lock steering to prograde.
    print "ascent complete" at (0,10).
    // wait until ship:verticalspeed <= -1.
    // stage.
    // wait until ship:STATUS = "SPLASHED".
    // stage.
}

main().