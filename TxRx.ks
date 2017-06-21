// Tx/Rx Library
// JEGHC.
// ToDo: Add persistance option (i.e. save queue to file... load queue from file as ship loads -> add to boot?)

global upload_waiting to false.
global download_waiting to false.
global to_upload to lexicon().
	// Value denotes upload type:
	//    - 0: move, append
	//    - 1: copy, append
	//    - 2: move, overwrite
	//    - 3: copy, overwrite
global to_download to lexicon().
	// Value denotes download type:
	//    - 0: append
	//    - 1: overwrite
global connection_last_seen to time:seconds.

// === Library Functions ================================================

function check_ksc_connection {
	// Check if there is a connection to KSC
	parameter craft.
	if addons:available("RT") {
		return addons:RT:HasKSCConnection(craft).
	} else {
		return HomeConnection:IsConnected.
	}
}

// === Upload Functions (to KSC Archives) ===============================

function upload_file {
	// Send a file to KSC archives
	parameter file_name.
	parameter upload_type is 0.
	
	if check_ksc_connection(ship) {
		perform_upload(file_name, upload_type).
		return 1.
	} else {
		queue_upload(file_name, upload_type).
		return 0.
	}
}

function perform_upload {
	// Perform act of uploading data
	parameter file_name.
	parameter upload_type is 0.
	// Value denotes upload type:
	//    - 0: move, append
	//    - 1: copy, append
	//    - 2: move, overwrite
	//    - 3: copy, overwrite
	
	if EXISTS("1:/local." + file_name) {
		local f to open("1:/local." + file_name).
		if not EXISTS("0:/" + file_name) CREATE("0:/" + file_name).
		local f2 to open("0:/" + file_name).
		
		if (upload_type > 1) f2:clear().
		
		local data to f:readall().
		f2:write(data).
		
		if (upload_type = 0) OR (upload_type = 2) {
			deletepath("1:/local."+file_name).
		}
		
		set connection_last_seen to time:seconds.
		return 1.
	} else {
		return 0.
	}
}

function queue_upload {
	// Queues a request to upload a file to the KSC archive.
	parameter file_name.
	parameter upload_type is 0.

	set upload_waiting to true.

	set to_upload[file_name] to upload_type.
}

function stream_data {
	// Uploads data direct to archive target file, only creating a local file when no connection is present.
	// ToDo: Need to check that there is sufficent space on volume.
	parameter file_name.
	parameter data.
	
	if check_ksc_connection(ship) {
		if not EXISTS("0:/" + file_name) CREATE("0:/" + file_name).
		local f to open("0:/" + file_name).
		f:writeln(data).
		return 1.
	} else {
		if not EXISTS("1:/local." + file_name) CREATE("1:/local." + file_name).
		local f to open("1:/local." + file_name).
		f:writeln(data).
		queue_upload(file_name, 0).
		return 1.
	}
	return 0.
}

when upload_waiting and check_ksc_connection(ship) then {
	// Perform queued uploads using active connection.
	set file_names to to_upload:keys.
	for a_file in file_names {
		perform_upload(a_file, to_upload[a_file]).
		to_upload:remove(a_file).
	}
	to_upload:clear().
	set upload_waiting to false.
	// Keep interrupt enabled.
	return true.
}


// === Download Functions (from KSC Archives) ============================
// ToDo: Make similar to upload file, with no-connection queue system (see functions below)
//	
//	function download_file {
//		// Recover a file from KSC archives
//		parameter file_name.
//		if check_ksc_connection(ship) AND {
//			local f_in to open("0:/" + file_name).
//			local f_out to open("1:/local." + file_name).
//			local data to f_in:readall().
//			f_out:write(data).
//			return 1.
//		} else {
//			return 0.
//		}
//	}
//	
//	function perform_download {
//	}
//	
//	function queue_download {
//	}
//	
//	when download_waiting and check_ksc_connection(ship) then {
//		// Perform queued downloads using active connection.
//	}