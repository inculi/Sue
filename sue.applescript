use framework "Foundation"
use scripting additions

using terms from application "Messages"
	
	on message sent theMessage with eventDescription
	end message sent
	
	on message received theText from theBuddy with eventDescription
		# this gets activated when it receives a direct message
		
		-- get attachments if there are any
		set fileName to "noFile"
		try
			tell application "Messages" to set f to the last file transfer
			if direction of f is incoming then
				-- compare diff in seconds
				if (current date) - (started of f) < 5 then
					set fFile to file of f
					set fileName to POSIX path of fFile
				end if
			end if
		on error fileError
			set fileName to "fileError"
		end try
		
		-- let Sue know she's only talking to one person.
		set chatId to "singleUser"
		
		try
			set buddyId to get id of theBuddy
		on error errMsg
			set errMsgParts to splitText(errMsg, "\"")
			set errCount to count of errMsgParts
			set buddyId to item (errCount - 1) of errMsgParts
		end try
		
		try
			set dollarSign to ASCII character 36
			set textBody to replace_chars(theText, dollarSign, "ÂÂÂ")
			set textBody to replaceText(textBody, "+", "ÄÄÄ")
			set buddyId to replace_chars(buddyId, dollarSign, "ÂÂÂ")
			set buddyId to replaceText(buddyId, "+", "ÄÄÄ")
			set chatId to replace_chars(chatId, dollarSign, "ÂÂÂ")
			set chatId to replaceText(chatId, "+", "ÄÄÄ")
			
			-- build curl command
			set command to "curl -X GET --data " & curlify("buddyId", buddyId) & " "
			set command to command & "--data " & curlify("chatId", chatId) & " "
			set command to command & "--data " & curlify("fileName", fileName) & " "
			set command to command & "--data " & curlify("textBody", textBody) & " "
			set command to command & " http://localhost:5000 "
			
			-- run in background
			set runBackground to "> /dev/null 2>&1 &"
			
			-- send inputs to server and return
			do shell script command & runBackground
			-- do shell script command & runBackground
			
			-- send inputs to server and return
		on error errorLog
			send errorLog to theBuddy
		end try
	end message received
	
	on chat room message received theText with eventDescription from theBuddy for theChat
		# this gets activated when a message is sent in a group text.
		
		-- get attachments if there are any
		set fileName to "noFile"
		try
			tell application "Messages" to set f to the last file transfer
			if direction of f is incoming then
				-- compare diff in seconds
				if (current date) - (started of f) < 5 then
					set fFile to file of f
					set fileName to POSIX path of fFile
				end if
			end if
		on error fileError
			set fileName to "fileError"
		end try
		
		-- use Otto's workaround to get the id of the group
		try
			set chatId to get id of theChat
		on error errMsg
			set errMsgParts to splitText(errMsg, "\"")
			set errCount to count of errMsgParts
			set chatId to item (errCount - 1) of errMsgParts
		end try
		
		try
			set buddyId to get id of theBuddy
		on error errMsg
			set errMsgParts to splitText(errMsg, "\"")
			set errCount to count of errMsgParts
			set buddyId to item (errCount - 1) of errMsgParts
		end try
		
		-- use the info we have to formulate our response
		try
			set dollarSign to ASCII character 36
			set textBody to replace_chars(theText, dollarSign, "ÂÂÂ")
			set textBody to replaceText(textBody, "+", "ÄÄÄ")
			set buddyId to replace_chars(buddyId, dollarSign, "ÂÂÂ")
			set buddyId to replaceText(buddyId, "+", "ÄÄÄ")
			set chatId to replace_chars(chatId, dollarSign, "ÂÂÂ")
			set chatId to replaceText(chatId, "+", "ÄÄÄ")
			
			-- build curl command
			set command to "curl -X GET --data " & curlify("buddyId", buddyId) & " "
			set command to command & "--data " & curlify("chatId", chatId) & " "
			set command to command & "--data " & curlify("fileName", fileName) & " "
			set command to command & "--data " & curlify("textBody", textBody) & " "
			set command to command & " http://localhost:5000 "
			
			-- run in background
			set runBackground to "> /dev/null 2>&1 &"
			
			-- send inputs to server and return
			do shell script command & runBackground
		on error errorLog
			send errorLog to theChat
		end try
	end chat room message received
	
	on active chat message received theText with eventDescription from theBuddy for theChat
		# this is bugged. Don't do anything.
		(*
		set getname to name of theBuddy as text
		try
			set myresult to get id of theBuddy
		on error errMsg
			set errMsgParts to splitText(errMsg, "\"")
			set errCount to count of errMsgParts
			set myresult to item (errCount - 1) of errMsgParts
		end try
		set finalText to replaceText(theText, "\"", "'")
		send myresult to theChat
		*)
	end active chat message received
	
	on addressed message received theText with eventDescription from theBuddy for theChat
	end addressed message received
	
	on received text invitation with eventDescription
	end received text invitation
	
	on received audio invitation theText from theBuddy for theChat with eventDescription
	end received audio invitation
	
	on received video invitation theText from theBuddy for theChat with eventDescription
	end received video invitation
	
	on buddy authorization requested with eventDescription
	end buddy authorization requested
	
	on addressed chat room message received with eventDescription
	end addressed chat room message received
	
	on login finished with eventDescription
	end login finished
	
	on logout finished with eventDescription
	end logout finished
	
	on buddy became available with eventDescription
	end buddy became available
	
	on buddy became unavailable with eventDescription
	end buddy became unavailable
	
	on received file transfer invitation theFileTransfer with eventDescription
		display dialog "received file transfer invitation"
	end received file transfer invitation
	
	on av chat started with eventDescription
	end av chat started
	
	on av chat ended with eventDescription
	end av chat ended
	
	on completed file transfer theFile with eventDescription
		display dialog "completed file transfer"
	end completed file transfer
	
end using terms from

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

on curlify(key, val)
	set curlString to "\"" & key & "=" & urlEncode(val) & "\""
	return curlString
end curlify

on splitText(sourceText, textDelimiter)
	set AppleScript's text item delimiters to {textDelimiter}
	set messageParts to (every text item in sourceText) as list
	set AppleScript's text item delimiters to ""
	return messageParts
end splitText

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

on replace_chars(this_text, search_string, replacement_string)
	set AppleScript's text item delimiters to the search_string
	set the item_list to every text item of this_text
	set AppleScript's text item delimiters to the replacement_string
	set this_text to the item_list as string
	set AppleScript's text item delimiters to ""
	return this_text
end replace_chars