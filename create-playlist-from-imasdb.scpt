#@osa-lang:AppleScript
------------------------------------
-- utilities
------------------------------------
on split(theText, aDelimiter)
	set tmp to AppleScript's text item delimiters
	set AppleScript's text item delimiters to aDelimiter
	set theList to every text item of theText
	set AppleScript's text item delimiters to tmp
	return theList
end split


------------------------------------
-- imasdb
------------------------------------

on isValidURL(aURL)
	(aURL starts with "https://imas-db.jp") or (aURL starts with "http://imas-db.jp")
end isValidURL

on setListFromURL(aURL)
	tell application "Safari"
		tell document 1
			set theTitle to do JavaScript "document.querySelector('#page_title').textContent"
			set theSongList to do JavaScript "Array.from(document.querySelectorAll('table.list > tbody > tr > td:nth-child(2)'), (x)=>x.textContent).join(',')"
		end tell
	end tell
	return {title:theTitle, songs:split(theSongList, ",")}
end setListFromURL


------------------------------------
-- Entry point
------------------------------------
tell application "Safari"
	tell document 1
		set theURL to URL

		if isValidURL(theURL) of me then
			set theEvent to setListFromURL(theURL) of me
			{theEvent's title, theEvent's songs}
		else
			display alert "You should run under imas-db.jp." & return & return & theURL & " isn't supported."
		end if
	end tell
end tell