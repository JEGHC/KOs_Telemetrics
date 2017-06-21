// Ascent Logging Library
// by JEGHC
// builds upon work by gisikw at https://github.com/gisikw/ksprogramming

run TxRx.

function init_log{
	print "Initialising Logs".
	
	// Clear previous logs
	if EXISTS("0:/ascent_data.js") DELETEPATH("0:/ascent_data.js").
	if EXISTS("1:/local.ascent_data.js") DELETEPATH("1:/local.ascent_data.js").
	
	stream_data("ascent_data.js", "var data = [['Time','Azimuth','Elevation','Throttle','Stage','Altitude','OrbitalVelocity','SurfaceVelocity','Apoapsis','Periapsis','Eccentricity','Inclination','DeltaV'],").
		// Simulation Data:
		// - Time
		
		// Control Data:
		// - Azimuth (angle to north - heading?)
		// - Elevation
		// - Throttle
		// - Stage
		
		// Flight Profile Data:
		// - Altitude
		// - OrbitalVelocity
		// - SurfaceVelocity
		// - Apoapsis
		// - Periapsis
		// - Eccentricity
		// - Inclination
		// - DeltaV

	set start_time to time:seconds.
}

function start_auto_log{
	global HiDefTick is 0.5.
	global LowDefTick is 2.0.
	global TickTimeLimit is HiDefTick.
	global LastTickTime is time:seconds.
	global LogRunning is true.
	
	when (time:seconds - LastTickTime > TickTimeLimit) then {
		set LastTickTime to time:seconds.
		log_telemetry().
		
		if check_ksc_connection(ship) {
			set TickTimeLimit to HiDefTick.
		} else {
			set TickTimeLimit to LowDefTick.
		}
		
		if LogRunning = true {
			return true.
		}
	}
}

function log_telemetry {
	local output is "[".

	// Time
	set output to output + (time:seconds - start_time) + ",".

	// Azimuth
	set angle to vang(north:vector, ship:facing:vector).
	set output to output + angle + ",".
	
	// Elevation
	set angle to 90 - vang(up:vector, ship:facing:vector).
	set output to output + angle + ",".
	
	// Throttle
	set output to output + throttle + ",".
	
	// Stage
	set output to output + stage:number + ",".
	
	// Altitude
	set output to output + alt:radar + ",".

	// OrbitalVelocity
	set output to output + ship:velocity:orbit:mag + ",".
	
	// SurfaceVelocity
	set output to output + ship:velocity:surface:mag + ",".
	
	// Apoapsis
	set output to output + apoapsis + ",".
	
	// Periapsis
	set output to output + max(periapsis,0) + ",".

	// Eccentricity
	set output to output + obt:eccentricity + ",".

	// Inclination
	set output to output + obt:inclination + ",".
	
	// DeltaV
	// ToDo: Review whole delta_V calculation process.
	// Fix: add solid fuel support to calculations!
	local ignition_count is 0.
	local active_isp is 0.
	list engines in ship_engines.
	set dry_mass to ship:mass - ((ship:liquidfuel + ship:oxidizer) * 0.005).
	for an_engine in ship_engines {
	    if an_engine:ignition AND NOT an_engine:throttlelock{	// detect if engine is lit and check it isn't a solid-boster
		    set active_isp to active_isp + an_engine:isp.
			set ignition_count to ignition_count + 1.
		}
	}
	if ignition_count > 0 {
		set active_isp to active_isp / ignition_count.
	} else {
		set active_isp to 0.
	}
	set delta_v to active_isp * 9.81 * ln(ship:mass / dry_mass).
	set output to output + delta_v + ",".
	
	// Throttle
	set output to output + throttle + "],".

	stream_data("ascent_data.js", output).
}

function close_log{
	set LogRunning to false.
	wait TickTimeLimit.
	stream_data("ascent_data.js", "];").
	
	if upload_waiting {
		print "Awaiting Connection for Data Upload.".
		until (upload_waiting = false) {
			wait 1.0.
		}
	}
}