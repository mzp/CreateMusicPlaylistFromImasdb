#@osa-lang:AppleScript
use framework "Foundation"

-- String manipulation
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

on regexReplace(aText as text, pattern as text, replacement as text)
	--require framework: Foundation
	set regularExpression to current application's NSRegularExpression's regularExpressionWithPattern:pattern options:0 |error|:(missing value)
	return (regularExpression's stringByReplacingMatchesInString:aText options:0 range:{location:0, |length|:count aText} withTemplate:replacement) as text
end regexReplace

-- levenshtein distance
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


-- imasdb
on imasDB(aURL)
	tell application "Safari"
		set d to count every window
		if d = 0 then
			make new window
			tell document 1
				set URL to aURL
			end tell
		else
			if aURL is not equal to "" then
				tell document 1
					set URL to aURL
				end tell
			end if
		end if

		page_loaded(10) of me

		set aSongList to do JavaScript "Array.from(document.querySelectorAll('table.list > tbody > tr > td:nth-child(2)'), (x)=>x.textContent).join(',')" in document 1
	end tell
	return split(aSongList, ",")
end imasDB

on page_loaded(timeout_value)
	repeat with i from 1 to (timeout_value * 10)
		tell application "Safari"
			if (do JavaScript "document.readyState" in document 1) is "complete" then
				return true
			else if i is the timeout_value then
				return false
			else
				delay 0.1
			end if
		end tell
	end repeat
	return false
end page_loaded

-- Music app
on addTrack(curItem, thePlaylist)
	set found to 0
	tell application "Music"
		-- ミツボシ☆☆★ -Happily Ever After Remix- => ミツボシ☆☆★
		set curItem to regexReplace(curItem, " +-.*-$", "") of me
		log curItem

		-- simlpe match
		set results to (every track of playlist 1 whose name contains curItem)
		if results is not {} then
			duplicate (get item 1 of results) to thePlaylist
			set found to 1
		else
			-- if not found, try to searh with edit distance
			repeat with aTrack in (every file track of playlist 1 whose album contains "CINDERELLA" or album artist contains "CINDERELLA" or artist contains "CINDERELLA")
				set aName to aTrack's name
				-- お願いシンデレラ! (M@STER VERSION) => お願いシンデレラ!
				set aName to regexReplace(aName, " +\\(.*\\)$", "") of me
				set aDistance to levenshteinDistance(curItem, aName) of me

				set aRatio to aDistance / (length of curItem)
				if aRatio < 0.3 then
					duplicate aTrack to thePlaylist
					set found to 1
					exit repeat
				end if
			end repeat
		end if
	end tell
	return found
end addTrack

on createPlayList(title, aURL)
	set theTitleList to imasDB(aURL)
	set theMissingList to {}
	tell application "Music"
		set playlistName to title
		-- Create Playlist if neened
		if name of every playlist contains playlistName then
			delete every track of playlist playlistName
			set thePlaylist to playlist playlistName
		else
			set thePlaylist to make new playlist with properties {name:playlistName}
		end if

		-- add tracks into the playsist
		with timeout of 60 seconds
			repeat with curItem in theTitleList
				set found to addTrack(curItem, thePlaylist) of me
				if found is 0 then
					set theMissingList to theMissingList & curItem
				end if
			end repeat
		end timeout

		return theMissingList
	end tell
end createPlayList

on matchTest(name)
	tell application "Music"
		set playlistName to "Playground"
		-- Create Playlist if neened
		if name of every playlist contains playlistName then
			delete every track of playlist playlistName
			set thePlaylist to playlist playlistName
		else
			set thePlaylist to make new playlist with properties {name:playlistName}
		end if

		-- add tracks into the playsist
		addTrack(name, thePlaylist) of me
	end tell
end matchTest

-- Usage example
set aMissingSongs to createPlayList("THE IDOLM@STER CINDERELLA GIRLS 7thLIVE TOUR Special 3chord♪ 名古屋公演 2日目", "http://imas-db.jp/song/event/cinderella7th1110.html")


