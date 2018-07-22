use framework "Foundation"
use scripting additions

on run argv
	tell application "Messages"
		try
			-- the id of the group chat we will respond to
			set chatId to item 1 of argv
			set chatId to my urlDecode(chatId)
			set chatId to my replaceText(chatId, "���", "+")
			set chatId to my replaceText(chatId, "���", "$")
			
			-- if it isn't a groupchat but rather a single person
			--   then this will be their number/email
			set recipientId to item 2 of argv
			set recipientId to my urlDecode(recipientId)
			set recipientId to my replaceText(recipientId, "���", "+")
			set recipientId to my replaceText(recipientId, "���", "$")
			
			-- sue's response that we will be sending.
			set responseMsg to item 3 of argv
			set responseMsg to my urlDecode(responseMsg)
			set responseMsg to my replaceText(responseMsg, "���", "+")
			set responseMsg to my replaceText(responseMsg, "���", "$")
			
			-- lets us know if sue is sending a file or message.
			set responseType to item 4 of argv
			
			-- check if she is sending a file or message
			if responseType is "file" then
				-- she is sending a file. Get the path.
				set filePath to item 4 of argv
				set filePath to my urlDecode(filePath)
				set filePath to my replaceText(filePath, "���", "+")
				set filePath to my replaceText(filePath, "���", "$")
				set fileResponse to POSIX file filePath
			else
				-- by default the only other option should be "msg"
				--   if we can figure out stickers or other things,
				--   then maybe we will add them as other cases.
				set fileResponse to false
			end if
			
			
			if chatId is "singleUser" then
				--sending messages to individual users.
				set theBuddy to a reference to buddy id recipientId
				-- set dMsg to my urlDecode(responseMsg)
				
				if fileResponse is false then
					send responseMsg to theBuddy
				else
					send fileResponse to theBuddy
				end if
			else
				-- sending messages to groups
				set thisChat to a reference to text chat id chatId
				-- set dMsg to my urlDecode(responseMsg)
				
				if fileResponse is false then
					send responseMsg to thisChat
				else
					send fileResponse to thisChat
				end if
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
