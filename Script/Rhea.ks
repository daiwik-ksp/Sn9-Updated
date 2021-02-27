// Rhea Launch Vehicle (Saturn Aerospace)
// CODEBASE version 0.5 - APACHE 2.0
//
// Created By:
// - QuasyMoFo
//
// Modified By:
//- D KSP programmer


// Primary Launch Settings
set missionApoapsis to 450000.
set missionPeriapsis to 450000.
set missionInclination to 0.
set flightMode to "Hop". // [Hop - Hop] [Static - Static Fire] [Orb - Flight to earth orbit]


// Other Launch Settings
set t to 0. // Launch Countdown
set fuelForFlight to 32500.
set stageTwoHeight to 50.5.
set startRoll to 270. // Number on left of navball
set g to body:mu / (body:radius + altitude) ^ 2.
set lz to latlng(-0.183186275053178,-74.4766386818981).// change the lat lang to your landing location
lock p to 90 - vAng(ship:facing:vector, ship:up:vector).
set aoa to 0.
set errorScaling to 1.
set steeringManager:maxstoppingtime to 2.
set steeringManager:rollts to 20. 


// Physics Range
SET KUNIVERSE:DEFAULTLOADDISTANCE:FLYING:UNLOAD TO 1760000. 
SET KUNIVERSE:DEFAULTLOADDISTANCE:FLYING:LOAD   TO 1769500.
WAIT 0.001.
SET KUNIVERSE:DEFAULTLOADDISTANCE:FLYING:PACK TO   1769999.
SET KUNIVERSE:DEFAULTLOADDISTANCE:FLYING:UNPACK TO 1769000.
WAIT 0.001.
SET KUNIVERSE:DEFAULTLOADDISTANCE:SUBORBITAL:UNLOAD TO 1760000. 
SET KUNIVERSE:DEFAULTLOADDISTANCE:SUBORBITAL:LOAD   TO 1769500.
WAIT 0.001.
SET KUNIVERSE:DEFAULTLOADDISTANCE:SUBORBITAL:PACK TO   1769999.
SET KUNIVERSE:DEFAULTLOADDISTANCE:SUBORBITAL:UNPACK TO 1769000.
WAIT 0.001.
SET KUNIVERSE:DEFAULTLOADDISTANCE:ORBIT:UNLOAD TO 1760000. 
SET KUNIVERSE:DEFAULTLOADDISTANCE:ORBIT:LOAD   TO 1769500.
WAIT 0.001.
SET KUNIVERSE:DEFAULTLOADDISTANCE:ORBIT:PACK TO   1769999.
SET KUNIVERSE:DEFAULTLOADDISTANCE:ORBIT:UNPACK TO 1769000.
WAIT 0.001.


// Initialisation
until t = 0 {
    clearscreen.
    print "T-" + t.
    wait 1.
    set t to t-1.

    on ag9 {
        ag9 off.
        ag6 off.
        lock throttle to 0.

        wait 0.1.
        reboot.
    }
}
if flightMode = "Hop" {
    set hopMode to 1.
} else if flightMode = "Static" {
    staticFire().
}
    


// Hop Test Sequence
until hopMode = 0 {

    if hopMode = 1 {
        stage.
        lock throttle to 1.15 * ship:mass * g / ship:availablethrust.
        wait 1.
        print "Lift off".
        if maxThrust < 1 {
            print "No Thrust, Aborting.".
            padAbort().
        }

        wait 0.1.
        stage.

        lock steering to heading(lz:heading, 90.5). 
        wait 2.
        set hopMode to 2.
    }

    if hopMode = 2 {
        // Engine out 1
        wait until alt:radar > 5000.
        lock steering to heading(lz:heading, 93).
        toggle ag2.

        // Engine out 2
        wait until alt:radar > 8500.
        lock steering to heading(lz:heading, 94).
        toggle ag3.

        // Throttle Reduction
        wait until apoapsis > 9500.
        lock steering to heading(lz:heading, 92).
        lock throttle to 0.65 * ship:mass * g / ship:availablethrust.

        // Fuel Transfer (to header tanks)
        wait until ship:verticalspeed < 20.
        set sourceFuelPart to ship:partstagged("AFTTank").
        set destFuelPart to ship:partstagged("FWDTank").
        set lfuelTransferFWD to transferAll("liquidfuel", sourceFuelPart, destFuelPart).
        set oxidTransferFWD to transferAll("oxidizer", sourceFuelPart, destFuelPart).
        set lfuelTransferFWD:active to true.
        set oxidTransferFWD:active to true.
        print " transfering fuel".
       
       

        wait until ship:verticalspeed < -1.
        lock throttle to 0.
        toggle ag1. // Engine 3 off
        toggle ag2. // Engine 1 on
        toggle ag3. // Engine 2 on
    
        rcs on.
        lock steering to heading(lz:heading, 0).
        toggle ag6. // AFT fins deploy
        wait 5.
        toggle ag5. // FWD fins deploy

        wait 1.
        set hopMode to 3.
    }

    if hopMode = 3 {
        set steeringManager:maxstoppingtime to 2.
        set steeringManager:rollts to 5.
        lock trueRadar to alt:radar - stageTwoHeight.
        lock maxDecel to (ship:availablethrust / ship:mass) - g.
        lock stopDist to ship:verticalspeed^2 / (2 * maxDecel).
        lock impactTime to trueRadar / abs(ship:verticalspeed).

        lock lngOff to (lz:lng - addons:tr:impactpos:lng) * 10472.

        if lngOff > 0 {
            set latErrorMulti to 50.
            set lngErrorMulti to 225. 
        } else {
            set latErrorMulti to -50.
            set lngErrorMulti to -225. 
        }

        lock latCorrection to (latError * latErrorMulti * 2).
        lock lngCorrection to (lngError * lngErrorMulti * 2).

        when (trueRadar < 8000) then {
            lock LatCorrection to (latError * LatErrorMulti * 6). // 2.5
            lock LngCorrection to (lngError * LngErrorMulti * 6). // 2.5
        }

        when (trueRadar < 3000) then {
            set lngErrorMulti to 500.
            lock LatCorrection to (latError * LatErrorMulti * 10). // 3.55
            lock LngCorrection to (lngError * LngErrorMulti * 10). // 3.55
            set steeringManager:maxstoppingtime to 5.
            }

        lock steering to heading(lz:heading, (0 + lngCorrection), (0 + latCorrection)).

        until (((stopDist + 250) + 75) > trueRadar) {
            wait 0.
            
        }
        toggle ag5.
        set hopMode to 4.
    }

    if hopMode = 4 {
       
       
    
        set radarOffset to 9.184.	 				// The value of alt:radar when landed (on gear)
 lock trueRadar to alt:radar - radarOffset.			// Offset radar to get distance from gear to ground
lock g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)
 lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
 lock stopDist to ship:verticalspeed^2 / (2 * maxDecel).		// The distance the burn will require
 lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
 lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact, used for landing gear

 WAIT UNTIL ship:verticalspeed < -1.
 	print "Preparing for hoverslam...".
 	rcs on.
 	brakes on.
	set aoa to - 5.
 	when impactTime < 3 then {gear on.}

 WAIT UNTIL trueRadar < stopDist.
     lock steering to getSteering().
 	print "Performing hoverslam".
 	lock throttle to idealThrottle.
wait until Alt:radar < 200.
set aoa to -3.
 WAIT UNTIL ship:verticalspeed > -0.01.
 set aoa to 0.
 	print "Hoverslam completed".
 	set ship:control:pilotmainthrottle to 0.
 	rcs off.
     lock steering to up.
     wait 5.
     shutdown.

     }

}

function getVectorSurfaceRetrograde{
	return -1*ship:velocity:surface.
}
function errorVector {
    return getImpact():position - lz:position.
}

function getSteering {            //the function for steering is here, the functions and vectors are calculated here and used elsewhere.
    
    local errorVector is errorVector().
        local velVector is -ship:velocity:surface.
        local result is velVector + errorVector*errorScaling.
        if vang(result, velVector) > aoa
        {
            set result to velVector:normalized
                          + tan(aoa)*errorVector:normalized.
        }

        return lookdirup(result, facing:topvector).
    }
  


// Static Fire
function staticFire {
    clearscreen.

    lock throttle to 1.
    stage.
    print "Ignition".
    wait 0.1.
    if maxThrust < 1 {
        print "No Thrust, Engine Auto Abort.".
        abort().
    }
    wait 3.
    lock throttle to 0.
    print "Shutdown".
    unlock steering.
    wait 1.
    ag10 off.
    reboot.
}


// Required Functions
function padAbort {
    ag6 off.
    ag9 off.
    lock throttle to 0.
    unlock steering.

    wait 0.1.
    reboot.
}

function getImpact {
    if addons:tr:hasimpact {
        return addons:tr:impactpos.
    }
    
    return ship:geoPosition.
}

function lngError {
    return getImpact():lng - lz:lng.
}

function latError {
    return getImpact():lat - lz:lat.
}

function positioningFunc {
    return getImpact():position - lz:position.
}

function steeringGuidance {
    local errorVector is positioningFunc().
    local velVector is -ship:velocity:surface.
    local result is velVector + errorVector * errorScaling.

    if vAng(result, velVector) > aoa {
        set result to velVector:normalized + tan(aoa) * errorVector:normalized.
    }

    return lookDirUp(result, facing:topvector).
}