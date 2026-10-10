//This library contains helper functions required by other functions, used in
//program flow, abstraction, and other programming practices that will be
//applied to functions throughout other library scripts.

//takes a condition statement as required parameter, and a string as an optional
//parameter, checks the condition statement, does nothing if it is true, and 
//prints the string, then forces a crash by dividing by zero
function require {
    parameter condition.
    parameter errorMessage is "Precondition failed".

    if not(condition) {
        print "ERROR: " + errorMessage.
        local x is 1.
        set x to x / 0.
    }
}