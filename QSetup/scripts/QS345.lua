local evt_TELE_FIRST = 109

local drawText = lcd.drawText
local drawList = qs_drawList
local saveDir = qs_path..'save/'
local blink = 0
local menue, editValue = 0, 0

local words = {
	'NO FILES FOUND!',																										--  1
	'Model Setup',																												--  2
	'Load Setup', 'Save Setup', 'Username',																			--  5
	'Model Name', 'Setup channels',																						--  7
	'Save new Setup', 'Overwrite Setup', 'Delete Setup',															-- 10
	'Description',																												-- 11
	'File to save', 																											-- 12
	'Channel ',	'Rename', ' Name',																						-- 15
	'Notice!|Changing the names|of the channels for|steering and|throttle is blocked.',					-- 16
	'DANGER!|Before changing the|channels, first switch|off the vehicle.',									-- 17
	'Start', 'Stop', 'Show Laps', 'Switch: ', 'Minimum Time: ', 'Save Laps', 'Clear Laps', 			-- 24
	'Lap Times', 'Lap ',																										-- 26
	'Press SYS to start|or stop timing', 'Laps saved', 'Laps cleared',										-- 29
	'Timing activated|To start, swing to|the line and then|give at least 95%|throttle.',				-- 30
	'Waiting to start',																										-- 31
	'Red 1', 'Green 1', 'Blue 1', 'Red 2', 'Green 2', 'Blue 2', 'Breathing', 'Speed',					-- 39
	'Language:', 'English',																									-- 41

	'KEINE DATEI GEFUNDEN!',
	nil,
	'Setup laden', 'Setup speichern', 'Benutzername',
	'Modellname', 'Setup Kanäle', 
	'Neues Setup speichern', 'Setup überschreiben', 'Setup löschen',
	'Beschreibung',
	'Datei auswählen',
	'Kanal ', 'Name', nil,
	'Hinweis!|Das ändern der|Namen der Kanäle|für Lenkung und|Gas ist gesperrt.',
	'ACHTUNG!|Vor dem Ändern der|Kanäle zuerst|Fahrzeug ausschalten!',
	nil, nil, 'Runden anzeigen', 'Schalter: ', 'Mindestzeit: ', 'Runden speichern', 'Runden löschen',
	'Rundenzeiten', 'Runde ',
	'Drücken sie SYS|zum starten oder|stoppen der Zeitnahme', 'Runden gespeichert', 'Runden gelöscht',
	'Zeitnahme aktiviert|Zum starten mit|schwung zur Linie|und dann mindestens|95% Gas geben.',
	'Warte auf Start',
	'Rot 1', 'Grün 1', 'Blau 1', 'Rot 2', 'Grün 2', 'Blau 2', 'Atmung', 'Geschwindigkeit',
	'Sprache:', 'Deutsch'
}

local filesOK
local fileSel = 1
local fileList = {}
local fileName = ''
local lapNum = 0

if not qs_listFirst[3022] then qs_listFirst[3022] = {1, 1} end

if qs_ltActive == -1 then
	qs_ltActive = 0
	if qs_readData(saveDir .. qs_getModelName() .. '.lap', qs_ltList, 1) then
		local dN = #qs_ltList
		qs_ltSwitch, qs_ltTW, qs_ltBest = qs_ltList[dN - 2], qs_ltList[dN - 1], qs_ltList[dN]
		for n = dN - 2, dN do qs_ltList[n] = nil end
	end
end

local function display(groupNum, event, siteNum, iSel, lg, editMode, lcdCnt, chnStr, chnThr)
	local floor = math.floor
	local drawTitel = qs_drawTitel
	blink = blink > 0 and blink - 1 or 20
	local rwSetup = 0
	local rwFN = ''
	local swapSrc, swapDest = 0, 0
	local space = ' '

	local modelName = qs_getModelName()

	-- local function lZeroes(v, strg, num)if n == 504 then break end 
		-- num = num or 1
		-- local chr = ''
		-- if num == 2 and v < 100 then chr = strg end
		-- if v < 10 then chr = chr..strg end
		-- return chr..v
	-- end

	local function msStrg(hs)
		local m = floor(hs / 6000)
		local cs = hs - m * 6000
		local s = floor(cs / 100)
		cs = cs - s * 100
		return (m < 10 and space or '') .. m .. ':' .. (s < 10 and '0' or '') .. s .. '.' .. (cs < 10 and '0' or '') .. cs
		-- local strg = '' .. (m < 10 and space or '') .. m .. ':' .. (s < 10 and '0' or '') .. s .. '.' .. (cs < 10 and '0' or '') .. cs
		-- if hundred then return '' .. (m < 100 and space or '') .. strg else return strg end
	end

	local function qs_tableSort(t)
		for n = 1, #t - 1 do
			while string.upper(t[n]) > string.upper(t[n + 1]) do
				t[n], t[n + 1] = t[n + 1], t[n]
				if n > 1 then n = n - 1 end end end
	end

	local function getText(n)							-- give the right word for selected language
		return words[lg * 41 - 41 + n] or words[n]
	end

	local function filesList(titel, filter, event)	-- list setup files to load or write
		if filter == nil then fileList = {} return end
		if #fileList < 1 then
			filesOK = false
			fileName = string.sub(saveDir, 1, #saveDir - 1)
			for fname in dir(fileName) do
				if string.sub(fname, 1, #filter) == filter then
					fileList[#fileList + 1] = string.sub(fname, #filter + 1, #fname)
				end
			end
			if #fileList > 0 then qs_tableSort(fileList) end
			fileSel = 1
		end
		if #fileList == 0 then		-- no files found
			drawText(64, 30, getText(1), CENTER + BOLD)
		return end
		filesOK, fileSel = true, drawList(titel, fileSel, fileList, event)
		if #fileList > 6 then
			for y = 12, 62, 2 do lcd.drawLine(126, y, 127, y + 1, SOLID, FORCE) end
			local h = 52 / #fileList * 6
			if h < 6 then h = 6 end
			local y = qs_listFirst[groupNum * 1000 + siteNum * 10]
			y = (52 - h) / (#fileList - 6) * (y - 1)
			lcd.drawFilledRectangle(126, y + 12, 2, h + 1, FORCE)
		end
	end

	if groupNum == 3 then
		if siteNum == 1 then		-- Load, save, username, modelname and channel setup
			if editMode == 1 or editMode == 2 and (iSel == 2 or iSel == 5) then
				local text = {} for n = 1, 5 do text[n] = getText(n + 2) end
				drawList(getText(2), iSel, text, 0, 5, 15, 10)
				if iSel == 1 then filesList() end
				if iSel == 3 then fileName = qs_username qs_inputText() end
				if iSel == 4 then fileName = qs_rcCar.name qs_inputText() end
			end
			if editMode == 2 or editMode == 3 then
				if iSel == 1 then													--Load Setup selected
					filesList(getText(3), modelName .. '~', event)
					if editMode == 3 and filesOK then
						rwFN, rwSetup = saveDir .. modelName .. '~' .. fileList[fileSel], 1
					end
				elseif iSel == 2 then groupNum = 4 							-- Save Setup selected
				elseif iSel == 3 then											-- Edit Username
					drawTitel(getText(5), MIDSIZE)
					fileName, editMode = qs_inputText(fileName, 13, editMode, event, ','), 2
					if event == evt_TELE_FIRST then
						qs_username = fileName == '' and 'your Name' or fileName
						editMode, event = 3, 0
						qs_writeConf()
					end
				elseif iSel == 4 then											-- Edit modelname
					drawTitel(getText(6), MIDSIZE)
					fileName, editMode = qs_inputText(fileName, 10, editMode, event, ','), 2
					if event == evt_TELE_FIRST then
						qs_rcCar.name = fileName
						editMode, event = 3, 0
						model.setInfo(qs_rcCar) qs_writeConf()
					end
				elseif iSel == 5 then groupNum = 5 							-- Edit channels (swap, rename)
				end
			end

		elseif siteNum == 2 then				-- Lap Timer
			if editMode == 1 or (editMode == 2 and iSel ~= 2) then		-- Lap Time menue
				drawList('Lap Timer', iSel, {getText(qs_ltActive ~= 0 and 19 or 18), getText(20),
					getText(23), getText(21) .. (qs_ltSwitch == 0 and 'SB' or 'SC'),
					getText(22) .. qs_ltTW / 100 .. 's', getText(24)},
					0, 5, 15, 10)
			end
			if editMode == 2 then
				if iSel == 1 then			-- Start and stop timing
					qs_ltActive = qs_ltActive ~= 0 and 0 or 1
					editMode = 3
					if qs_ltActive == 1 then
						qs_setPopup({getText(30)}, 80)
						playFile('trnstart.wav') end

				elseif iSel == 2 then		-- Show lap times
					local ltNumber, sel, lf, y = #qs_ltList - 1, qs_listFirst[3022][2], qs_listFirst[3022][1], 13
					if event == 101 then sel = sel == ltNumber and 1 or ltNumber end	-- PAGE> to move to 1 and last
					if event == evt_TELE_FIRST then		-- TELE to move selector to best time(s)
						for n = 1, ltNumber do
							sel = sel == ltNumber and 1 or sel + 1
							if qs_ltBest == qs_ltList[sel + 1] - qs_ltList[sel] then break end
						end end
					drawText(12, 121, 'TELE', 2048 + INVERS + SMLSIZE)
					drawText(32, 121, 'Best', 2048 + SMLSIZE)
					drawText(12, 1, 'PAGE>', 2048 + INVERS + SMLSIZE)
					drawText(37, 1, '\127-\126', 2048 + SMLSIZE)
					if ltNumber > 0 then
						if lapNum < ltNumber then lapNum, sel = ltNumber, ltNumber end
						sel = qs_adjVal(sel, 1, ltNumber, -getRotEncSpeed(), event, 800)
						if sel < lf then lf = sel elseif sel - 4 > lf then lf = sel - 4 end
						qs_listFirst[3022][1] = lf
						for n = lf, lf + 4 do
							local d = qs_ltList[n + 1] - qs_ltList[n]
							lcd.drawText(42, y, getText(26), RIGHT + SMLSIZE)
							local xL = lcd.getLastLeftPos() - 2
							lcd.drawText(58, y, (n < 100 and space or '') .. (n < 10 and space or '') .. n .. ':', RIGHT + SMLSIZE)
							lcd.drawText(108, y, msStrg(d), RIGHT + SMLSIZE)
							if n == sel then lcd.drawFilledRectangle(xL, y - 1, lcd.getLastRightPos() - xL + 1, 8, 0) end
							if d == qs_ltBest then lcd.drawText(110, y, '\127-', SMLSIZE) end
							if n == ltNumber then break end
							y = y + 7
						end
						qs_listFirst[3022][2] = sel
						local total = qs_ltList[ltNumber + 1] - qs_ltList[1]
						lcd.drawText(64, 49, 'Total: ' .. (total < 600000 and ' ' or '') .. msStrg(total), CENTER)
						lcd.drawText(64, 57, 'Avg: ' .. msStrg(floor(total / ltNumber)) .. ' Best: ' .. msStrg(qs_ltBest), CENTER)
					end
					if qs_ltActive == 1 then
						if qs_ltLapTime then
							drawText(1, 0, getText(26) .. ltNumber + 1, MIDSIZE)
							drawText(127, 0, msStrg(qs_ltLapTime), MIDSIZE + RIGHT)
						else
							drawText(64, 0, getText(31), MIDSIZE + CENTER)
						end
						lcd.drawFilledRectangle(0, 0, 128, 12, 0)
					else drawTitel(getText(25), MIDSIZE) end
					if ltNumber < 1 and qs_ltActive == 0 then qs_setPopup({'[i]', getText(27)}, 1) end		-- nothing to show
					if event == 110 then qs_ltActive = qs_ltActive ~= 0 and 0 or 1
						playFile(qs_ltActive == 1 and 'trnstart.wav' or '') end

				elseif iSel == 3 then
					local f1 = io.open(saveDir .. modelName .. '.lap', 'w')
					local f2 = io.open(saveDir .. modelName .. '.csv', 'w')
					io.write(f2, getText(26), ';', getText(25), '\r')
					local ltNumber = #qs_ltList
					for n = 1, ltNumber do
						io.write(f1, qs_ltList[n], ',')
						if n > 1 then
							local d = qs_ltList[n] - qs_ltList[n - 1]
							io.write(f2, n - 1, ';', d / 100, '\r')
						end
					end
					io.write(f1, qs_ltSwitch, ',', qs_ltTW, ',', qs_ltBest)
					if ltNumber > 1 then
						local total = qs_ltList[ltNumber] - qs_ltList[1]
						total = total / 100
						io.write(f2, 'Total;', total, '\r', 'Average;', total / (ltNumber - 1), '\rBest;', qs_ltBest / 100)
					end
					io.close(f1)
					io.close(f2)
					editMode = 3
					qs_setPopup({'[i]', getText(28)})
				elseif iSel == 4 then		-- switch the trigger for laps
					qs_ltSwitch = qs_ltSwitch == 0 and 1 or 0
					editMode = 3
				elseif iSel == 5 then
					local val = qs_adjVal(qs_ltTW / 100, 0, 40, 1, event)
					qs_setPopup({getText(22),'' .. val .. 's'}, 1)
					qs_ltTW = val * 100
				elseif iSel == 6 then
					qs_ltActive, qs_ltList, lapNum, editMode, qs_listFirst[3022][2] = 0, {}, 0, 3, 1
					qs_setPopup({'[i]', getText(29)})
				end
			end

						-- setup the LED ambient light
		elseif siteNum == 3 then
			local text = {}
			for n = 32, 39 do text[n - 31] = getText(n) end
			editMode = drawList('LED-Setup', iSel, text, event, 5, 14, 10, 64, qs_LED, '%%%%%%%\64',
			{0, 0, 0, 0, 0, 0, 0, 0,   100, 100, 100, 100, 100, 100, 100, 180}, editMode, nil, {2.55, 2.55, 2.55, 2.55, 2.55, 2.55, .01})
			if editMode == 1 then editValue = qs_LED[iSel]
			elseif editMode == 3 and editValue ~= qs_LED[iSel] then qs_writeConf()
			elseif editMode == 4 then qs_LED[iSel] = editValue end

		elseif siteNum == 4 then  -- my about site
			drawText(64,2, 'Quick Setup MT12', MIDSIZE + CENTER)
			drawText(63,14, 'v24.06.26', CENTER)
			drawText(63,44, 'Developed 2024 by', CENTER)
			drawText(64,51, 'Andreas Kassner', MIDSIZE + CENTER)
			if editMode == 1 then editValue = lg
			elseif editMode == 2 then qs_lang = qs_adjVal(lg, 1, 2, 1, event, 1000)
			elseif editMode == 3 then qs_writeConf()
			elseif editMode == 4 then qs_lang = editValue end
			drawText(62, 29, getText(40), RIGHT)
			drawText(65, 29, getText(41), INVERS + (editMode == 2 and BLINK or 0))
			lcd.drawNumber(127, 14, getAvailableMemory(), RIGHT + SMLSIZE)

						-- prints the character set
		elseif siteNum == 5 then
			local cx, x, y = 8, 0, 0
			for n = (iSel - 1) * 128 / cx * 64 / cx, iSel * 128 / cx * 64 / cx do
				if n > 255 then break end
				lcd.drawText(x, y, string.char(n), 0)
				x = x + cx
				if x > 127 then x, y = 0, y + cx end
			end
			if iSel == 1 then drawText(128, 0, getAvailableMemory(), RIGHT + SMLSIZE) end
		end

		if event == evt_TELE_FIRST and editMode == 1 then qs_popGroup() groupNum = 2 end

	elseif groupNum == 4 then	-- save new, overwrite or delete setup
		if editMode == 1 then
			drawList(getText(4), iSel, {getText(8), getText(9), getText(10)}, 0, 3, 20, 12)
			if iSel == 1 then fileName = qs_inputText() end
			if iSel == 2 or iSel == 3 then filesList() end
		elseif editMode == 2 or editMode == 3 then
			if iSel == 1 then														-- Save new setup
				drawTitel(getText(11), MIDSIZE)
				fileName = qs_inputText(fileName, 21, editMode, event, '"?\\|/*<>:')
				editMode, lcdCnt = 2, 0
				if event == evt_TELE_FIRST then
					rwFN, rwSetup, editMode = saveDir .. modelName .. '~' .. fileName, 2, 3
				end
			elseif iSel == 2 then												-- Overwrite setup
				filesList(getText(12), modelName .. '~', event)
				if editMode == 3 and filesOK then
					rwFN, rwSetup = saveDir .. modelName .. '~' .. fileList[fileSel], 2
				end
			elseif iSel == 3 then												-- Delete setup
				filesList(getText(10), modelName .. '~', event)
				if editMode == 3 and filesOK then
					del(saveDir..modelName .. '~' .. fileList[fileSel])
				end
			end
		end
		if editMode > 2 then qs_listFirst[4010] = 1 end

	elseif groupNum == 5 then								-- Setup channels (move and rename)
		if editMode == 4 then menue = 0 end
		if menue == 0 then
			if event == evt_TELE_FIRST then
				if editMode == 1 then
					local i = iSel - 1
					if i == chnStr or i == chnThr or i == qs_channelStB then
						qs_setPopup({getText(16)}, 50)
					else
						menue = 1 qs_inputText()
					end
				end
			end
			drawTitel(getText(7), MIDSIZE)
			local x, y, x1 = 74, 14, 0
			for n = 1, 6 do
				local name = model.getOutput(n - 1).name
				drawText(x, y, getText(13)..n..': ', RIGHT)
				x1 = lcd.getLastLeftPos()
				drawText(x, y, name, 0)
				local x2 = lcd.getLastPos()
				if iSel == n then
					fileName = name
					if editMode == 1 or (editMode == 2 and blink > 8) then
						lcd.drawFilledRectangle(x1 - 2, y - 1, x2 - x1 + 3, 9, 0) end
				end
				y = y + 8
			end
			drawText(1, 113, getText(14), 2048 + SMLSIZE)
			drawText(2, 121, 'TELE', 2048 + INVERS + SMLSIZE)
			if editMode == 2 then
				if getRSSI() > 0 then
					qs_setPopup({getText(17)}, 50)
					editMode = 3
				end
				if iSel > 1 then drawText(x1 - 10,  2 + iSel * 8, CHAR_UP, 0) end
				if iSel < 6 then drawText(x1 - 10, 10 + iSel * 8, CHAR_DOWN, 0) end
				local src = iSel
				iSel = qs_adjVal(iSel, 1, 6, -1, event)
				swapSrc, swapDest = src - 1, iSel - 1
				if iSel ~= src then blink = 20 end
			end
		else
			drawTitel(getText(13)..iSel..getText(15), MIDSIZE)
			fileName = qs_inputText(fileName, 4, editMode, event, ',')
			editMode = 2
			if event == evt_TELE_FIRST then
				local output = model.getOutput(iSel - 1)
				output.name = fileName
				model.setOutput(iSel - 1, output)
				editMode = 3 menue = 0
			end
		end
	end

	if swapSrc ~= swapDest then			-- Swap channels if source and dest not equal
		local mixOut1, mixOut2 = {}, {}
		for n = 1, model.getMixesCount(swapSrc) do mixOut1[n] = model.getMix(swapSrc, 0) model.deleteMix(swapSrc, 0) end
		for n = 1, model.getMixesCount(swapDest) do mixOut2[n] = model.getMix(swapDest, 0) model.deleteMix(swapDest, 0) end
		for n = 1, #mixOut2 do model.insertMix(swapSrc, n - 1, mixOut2[n]) end
		for n = 1, #mixOut1 do model.insertMix(swapDest, n - 1, mixOut1[n]) end
		mixOut1, mixOut2 = model.getOutput(swapSrc), model.getOutput(swapDest)
		model.setOutput(swapSrc, mixOut2) model.setOutput(swapDest, mixOut1)
		qs_init(1)
	end

	if rwSetup == 2 then							-- Write Setup (rwSetup = 2)
		local f = io.open(rwFN, 'w')
		for c = 0, 8 do
			io.write(f, model.getGlobalVariable(c, 0)..', ')
		end
		for c = chnStr, chnThr, chnThr - chnStr do
			for m = 1, model.getMixesCount(c) do
				local out = model.getMix(c, m - 1)
				io.write(f, out.speedUp, ', ', out.speedDown, ', ')
			end
			local out = model.getOutput(c)
			io.write(f, out.min, ', ', out.max,  ', ', out.revert, ', ')
		end
		io.close(f)
	elseif rwSetup == 1 then					-- Read Setup (rwSetup = 1)
		local d = {}
		if qs_readData(rwFN, d) then
			for p = 1, 9 do model.setGlobalVariable(p - 1, 0, d[p]) end
			local p = 10
			for c = chnStr, chnThr, chnThr - chnStr do
				for m = 1, model.getMixesCount(c) do
					local out = model.getMix(c, m - 1)
					out.speedUp = d[p]
					out.speedDown = d[p + 1]
					model.deleteMix(c, m - 1)
					model.insertMix(c, m - 1, out)
					p = p + 2
				end
				local out = model.getOutput(c)
				out.min = d[p]
				out.max = d[p + 1]
				out.revert = d[p + 2]
				p = p + 3
				model.setOutput(c, out)
			end
		end
	end

	return editMode, lcdCnt, iSel, groupNum
end
return display
