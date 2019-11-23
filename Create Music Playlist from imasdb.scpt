#@osa-lang:AppleScript
use framework "Foundation"
use scripting additions

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
-- Music
------------------------------------
on normalize(aTitle)
	-- ミツボシ☆☆★ -Happily Ever After Remix- => ミツボシ☆☆★
	set theTitle to regexReplace(aTitle, " +-.*-$", "") of me
	-- お願いシンデレラ! (M@STER VERSION) => お願いシンデレラ!
	set theTitle to regexReplace(theTitle, " +\\(.*\\)$", "") of me
	return theTitle
end normalize

on addTrack(aSong, aPlaylist)
	set found to 0
	tell application "Music"
		-- simlpe match
		set results to (every track of playlist 1 whose name contains aSong)
		if results is not {} then
			duplicate (get item 1 of results) to aPlaylist
			set found to 1
		else
			-- if not found, try to searh with edit distance
			repeat with aTrack in (every file track of playlist 1 whose album contains "CINDERELLA" or album artist contains "CINDERELLA" or artist contains "CINDERELLA" or name contains "M@STER VERSION")
				log aSong & " compare with " & aTrack's name
				set aDistance to levenshteinDistance(aSong, normalize(aTrack's name) of me) of me
				set aRatio to aDistance / (length of aSong)
				if aRatio < 0.3 then
					duplicate aTrack to aPlaylist
					set found to 1
					exit repeat
				end if
			end repeat
		end if
	end tell

	return found
end addTrack

on createPlayList(aEvent)
	set theMissingList to {}
	set theSongList to aEvent's songs
	tell application "Music"
		-- Create Playlist if neened
		set thePlaylistTitle to aEvent's title
		if name of every playlist contains thePlaylistTitle then
			delete every track of playlist thePlaylistTitle
			set thePlaylist to playlist thePlaylistTitle
		else
			set thePlaylist to make new playlist with properties {name:thePlaylistTitle}
		end if

		-- add tracks into the playsist
		with timeout of 60 seconds
			repeat with curItem in theSongList
				set curItem to normalize(curItem) of me
				set found to addTrack(curItem, thePlaylist) of me
				if found is 0 then
					set theMissingList to theMissingList & curItem
				end if
			end repeat
		end timeout
	end tell

	return theMissingList
end createPlayList


------------------------------------
-- Entry point
------------------------------------
tell application "Safari"
	tell document 1
		set theURL to URL

		if isValidURL(theURL) of me then
			set theEvent to setListFromURL(theURL) of me
			set theMissings to createPlayList(theEvent) of me

			if theMissings is {} then
				display alert theEvent's title & " is created"
			else
				display alert theEvent's title & " is created, but can't find following sons:" & return & return & join(theMissings, return) of me
			end if
		else
			display alert "You should run under imas-db.jp." & return & return & theURL & " isn't supported."
		end if
	end tell
end tell


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

on join(theList, theDelimiter)
	set theBackup to AppleScript's text item delimiters
	set AppleScript's text item delimiters to theDelimiter
	set theString to theList as string
	set AppleScript's text item delimiters to theBackup
	return theString
end join

-- https://qiita.com/szk-3/items/4f63358eca91122993e2
on regexReplace(aText as text, pattern as text, replacement as text)
	--require framework: Foundation
	set regularExpression to current application's NSRegularExpression's regularExpressionWithPattern:pattern options:0 |error|:(missing value)
	return (regularExpression's stringByReplacingMatchesInString:aText options:0 range:{location:0, |length|:count aText} withTemplate:replacement) as text
end regexReplace

-- https://macscripter.net/viewtopic.php?id=43966
on levenshteinDistance(s1, s2)
	set xLen to (count s1)
	set yLen to (count s2)

	if xLen ≤ 1 then
		return yLen
	end if

	if yLen ≤ 1 then
		return xLen
	end if

	script o
		property charList1 : id of s1 -- For everything sensitivity â€¦
		property charList2 : id of s2 -- â€¦ and speed.
		property previousRow : missing value
		property currentRow : missing value
	end script

	-- Return 0 straight away if the two strings are equal.
	if (o's charList1 = o's charList2) then return 0

	-- Otherwise intitialise two "row" lists as the first row of a notional matrix.
	set o's previousRow to {0} & o's charList1
	repeat with x from 1 to xLen
		set item (x + 1) of o's previousRow to x
	end repeat
	set o's currentRow to o's previousRow's items
	-- Handle the remaining rows in a rolling manner, the two lists alternating as previous and current rows.
	repeat with y from 1 to yLen
		set item 1 of o's currentRow to y
		repeat with x from 1 to xLen
			set deletion to (item x of o's currentRow) + 1
			if (item x of o's charList1 is item y of o's charList2) then
				set alternate to (item x of o's previousRow)
			else
				set alternate to (item x of o's previousRow) + 1
			end if
			set min to (item (x + 1) of o's previousRow) + 1
			if (deletion < min) then set min to deletion
			if (alternate < min) then set min to alternate

			set item (x + 1) of o's currentRow to min
		end repeat

		tell o's previousRow
			set o's previousRow to o's currentRow
			set o's currentRow to it
		end tell
	end repeat

	return end of o's previousRow
end levenshteinDistance
