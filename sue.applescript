using terms from application "Messages"
	
	
	on message sent theMessage with eventDescription
	end message sent
	
	on message received theText from theBuddy with eventDescription
		set buddyId to get id of theBuddy
		set inputText to replaceText(theText, "\"", "ÂÂÂ")
		set finalText to do shell script "echo \"" & buddyId & "|~|" & inputText & "\"" & " | python /Users/lucifius/Documents/prog/Sue/a.py" as text without altering line endings
		send finalText to theBuddy
	end message received
	
	on chat room message received theText with eventDescription from theBuddy for theChat
		set buddyId to get id of theBuddy
		set inputText to replaceText(theText, "\"", "ÂÂÂ")
		set finalText to do shell script "echo \"" & buddyId & "|~|" & inputText & "\"" & " | python /Users/lucifius/Documents/prog/Sue/a.py" as text without altering line endings
		send finalText to theChat
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
	end received file transfer invitation
	
	on av chat started with eventDescription
	end av chat started
	
	on av chat ended with eventDescription
	end av chat ended
	
	on completed file transfer with eventDescription
	end completed file transfer
	
end using terms from

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
