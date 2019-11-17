#!/usr/bin/osascript
use framework "Foundation"
use scripting additions

on run argv
	tell application "Messages"
		try
			set myid to get id of first service
			
			set recipient to item 1 of argv
			set recipient to my urlDecode(recipient)
			set recipient to my replaceText(recipient, "ÄÄÄ", "+")
			
			set talkMethod to item 2 of argv
			
			set theMessage to item 3 of argv
			set theMessage to my urlDecode(theMessage)
			set theMessage to my replaceText(theMessage, "ÄÄÄ", "+")
			set theMessage to my replaceText(theMessage, "ÂÂÂ", "$")
			
			set theBuddy to buddy recipient of service id myid
			send theMessage to theBuddy
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