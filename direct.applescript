use framework "Foundation"
use scripting additions

on run argv
	tell application "Messages"
		try
			set chatId to item 1 of argv
			set recipientId to item 2 of argv
			set responseMsg to item 3 of argv
			
			if chatId is "singleUser" then
				--sending messages to individual users.
				set theBuddy to a reference to buddy id recipientId
				set dMsg to my urlDecode(responseMsg)
				send dMsg to theBuddy
			else
				-- sending messages to groups
				set thisChat to a reference to text chat id chatId
				set dMsg to my urlDecode(responseMsg)
				send dMsg to thisChat
			end if
		on error fileError
			tell application "System Events" to display dialog fileError
		end try
	end tell
end run

on urlEncode(input)
	tell current application's NSString to set rawUrl to stringWithString_(input)
	set theEncodedURL to rawUrl's stringByAddingPercentEscapesUsingEncoding:4 -- 4 is NSUTF8StringEncoding
	return theEncodedURL as Unicode text
end urlEncode

on urlDecode(theText)
	set theString to stringWithString_(theText) of NSString of current application
	set theEncoding to NSUTF8StringEncoding of current application
	set theAdjustedString to stringByReplacingPercentEscapesUsingEncoding_(theEncoding) of theString
	return (theAdjustedString as string)
end urlDecode