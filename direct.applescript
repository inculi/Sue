use framework "Foundation"
use scripting additions

on run argv
	tell application "Messages"
		try
			set chatId to item 1 of argv
			set chatId to my urlDecode(chatId)
			set chatId to my replaceText(chatId, "ÄÄÄ", "+")
			set chatId to my replaceText(chatId, "ÂÂÂ", "$")
			set recipientId to item 2 of argv
			set recipientId to my urlDecode(recipientId)
			set recipientId to my replaceText(recipientId, "ÄÄÄ", "+")
			set recipientId to my replaceText(recipientId, "ÂÂÂ", "$")
			set responseMsg to item 3 of argv
			set responseMsg to my urlDecode(responseMsg)
			set responseMsg to my replaceText(responseMsg, "ÄÄÄ", "+")
			set responseMsg to my replaceText(responseMsg, "ÂÂÂ", "$")
			
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

on replaceText(someText, oldItem, newItem)
	set {tempTID, AppleScript's text item delimiters} to {AppleScript's text item delimiters, oldItem}
	try
		set {itemList, AppleScript's text item delimiters} to {text items of someText, newItem}
		set {someText, AppleScript's text item delimiters} to {itemList as text, tempTID}
	on error errorMessage number errorNumber
		set AppleScript's text item delimiters to tempTID
		error errorMessage number errorNumber
	end try
	
	return someText
end replaceText
