
// Created By:
// - QuasyMoFo
//
// Modified By:
//- D KSP programmer

clearscreen.
//-----------------------Launch Settings-----------------------------//
set lz to latlng(-0.0972481973484359,-74.4776645088652).// change the lat lang to your landing location
set SburnAlt to 900.// change this to change the altitude you want the landing burn to start 

//---------Do Not Change these settings ------------//
lock aoa to 0.
set steeringManager:maxstoppingtime to 2.
set steeringManager:rollts to 20. 
set hopMode to 1.	 		
lock trueRadar to alt:radar .
set errorScaling to 1.
//----------------------------------------------------//
	
until hopMode = 0 {

    if hopMode = 1 {
        stage.
        setThrustTOWeight(1.5).
        wait 1.
        print "Lift off".
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
        setThrustTOWeight(0.35).
       
       

        wait until ship:verticalspeed < -1.
        //----------Belley Flop starts here----------------// 
        lock throttle to 0.
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

        lock lngOff to (lz:lng - addons:tr:impactpos:lng) * 10472.

        if lngOff > 0 {
            set latErrorMulti to 50.
            set lngErrorMulti to 225. 
        } else {
            set latErrorMulti to -50.
            set lngErrorMulti to -225. 
        }

        lock latCorrection to (latError() * latErrorMulti * 2).
        lock lngCorrection to (lngError() * lngErrorMulti * 2).

        when (trueRadar < 8000) then {
            lock LatCorrection to (latError() * LatErrorMulti * 6). // 2.5
            lock LngCorrection to (lngError() * LngErrorMulti * 6). // 2.5
        }

        when (trueRadar < 3000) then {
            set lngErrorMulti to 500.
            lock LatCorrection to (latError() * LatErrorMulti * 10). // 3.55
            lock LngCorrection to (lngError() * LngErrorMulti * 10). // 3.55
          
            }

        

        until (alt:radar < SburnAlt) {
           lock steering to heading(lz:heading, (0 + lngCorrection), (0 + latCorrection)).
            
        }
        toggle ag5.
        
        set hopMode to 4.
    }

    if hopMode = 4 { 
//----------This is where the crazy landing starts----------------//    
 	rcs on.
 	brakes on.
	lock aoa to - 10.
    lock steering to  getSteering().
    setHoverPIDLOOPS().
    setHoverAltitude(100).
    setHoverDescendSpeed(35).
    WAIT 2.
    TOGGLE AG1.
    lock aoa to -6.
    wait until alt:radar < 1000.
    setHoverDescendSpeed(35).
    wait until alt:radar < 500.
    lock steering to getVectorSurfaceRetrograde().
    setHoverDescendSpeed(25).
    wait until alt:radar < 200 .
    setHoverDescendSpeed(6).
    gear on.
    WAIT UNTIL ALT:radar < 100.
    lock steering to getVectorSurfaceRetrograde().
    wait until ship:status = "landed".
    print "landed".
    lock throttle to 0.
    lock steering to up.
    wait 2000.
    shutdown.
 }
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


function setHoverPIDLOOPS{
	//Controls altitude by changing climbPID setpoint
	SET hoverPID TO PIDLOOP(1, 0.01, 0.0, -50, 50). 
	//Controls vertical speed
	SET climbPID TO PIDLOOP(0.1, 0.3, 0.005, 0, 1). 
	//Controls horizontal speed by tilting rocket
	SET eastVelPID TO PIDLOOP(3, 0.01, 0.0, -20, 20).
	SET northVelPID TO PIDLOOP(3, 0.01, 0.0, -20, 20). 
	 //controls horizontal position by changing velPID setpoints
	SET eastPosPID TO PIDLOOP(1700, 0, 100, -40,40).
	SET northPosPID TO PIDLOOP(1700, 0, 100, -40,40).
}

function setHoverAltitude{ //set just below landing altitude to touchdown smoothly
	parameter a.
	SET hoverPID:SETPOINT TO a.
}

function setHoverDescendSpeed{
	parameter a.
	SET hoverPID:MAXOUTPUT TO a.
	SET hoverPID:MINOUTPUT TO -1*a.
	SET climbPID:SETPOINT TO hoverPID:UPDATE(TIME:SECONDS, SHIP:ALTITUDE). //control descent speed with throttle
	lock throttle TO climbPID:UPDATE(TIME:SECONDS, SHIP:VERTICALSPEED).	
}

function setThrustTOWeight{
parameter thrToWeight.
lock g to constant:g * body:mass / body:radius^2.
lock thrott to thrToWeight * ship:mass * g / ship:availablethrust.
lock throttle to thrott.
}

function sendCommToVessel{
	parameter v.
	parameter msg.
	SET C TO v:CONNECTION.
	C:SENDMESSAGE(msg).
}

