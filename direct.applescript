on run argv
	tell application "Messages"
		try
			set myid to "iMessage;+;chat" & item 1 of argv
			set fileName to item 2 of argv
			--set ImageAttachment to POSIX file fileName as alias
			set ImageAttatchment to choose file fileName with multiple selections allowed
			set theBuddy to a reference to text chat id myid
			send ImageAttachment to theBuddy
		on error fileError
			tell application "System Events" to display dialog fileError
		end try
	end tell
end run
