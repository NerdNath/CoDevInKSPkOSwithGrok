//This is the unique script for the tentative 5 vehicle and its mission.

clearscreen.
lock steering to up.
lock throttle to 1.
wait until stage:ready.
stage.

wait until apoapsis > 11000.
lock throttle to 0.

wait until alt:radar > 7000 and ship:airspeed > 75.

stage.

// until false {
//     if ship:verticalSpeed < 0{
//         for part in ship:parts {
//             if part:HASMODULE("ModuleParachute") {
//                 part:getmodule("ModuleParachute"):doevent("Deploy Chute").
//             }
//         }
//         break.
//     }
// }

wait until stage:ready.
stage.

gear on.