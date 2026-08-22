local evt_TELE_FIRST = 109
local evt_SYS_LONG = 142
local evt_MDL_FIRST = 108

local saveDir = qs_path..'save/'
local drawText = lcd.drawText
local drehung = 0
local menue = 0
local editValue = 0
local editName = ''

local evtActive, evtStart, evtDist, evtRuns = 0, 0, 5, 1

local yn = 0

local trimThr = model.getGlobalVariable(6, 0)

local ws4Text = {'Front only', 'Front/Back', 'Back only', 'Front/Back rev.'}

local monthsWeekdays = {
	'Thursday', 'Friday', 'Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday',
	'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December',

	'Donnerstag', 'Freitag', 'Samstag', 'Sonntag', 'Montag', 'Dienstag', 'Mittwoch',
	'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'
}

local words = {
	
	'Str', 'Thr', 																	--  2
	'DANGER!|Battery voltage|at limit: ', 'Please load!', 			--  4
	'FwR:', 'ABS', 'Trim ST:', 'L', 'R', 'D/R:', 'BrR:', 				-- 11
	'CH', 																			-- 12
	'Clock', 'Analog', 'Digital', 											-- 15
	'off', 'on', 																	-- 17
	'Look', 																			-- 18
	'Trim Thr', 'Brake', 'Forward',											-- 21
	'Set Event', 'Start Time', 'Distance', 'Runs', 'Run ', ' in',	-- 27
	'Stop Event?', 'no', 'yes',												-- 30
	'Start time',																	-- 31

	'Lnk', 'Gas', 
	'ACHTUNG!|Batteriespannung|am Limit: ', 'Bitte laden!',
	'VwR:', nil, nil, nil, nil, nil, nil, 
	'KN', 
	'Uhr', nil, nil,
	'aus', 'an',
	'Layout',
	'Trim Gas', 'Bremse', 'Vorwärts',
	'Setze Ereignis', 'Startzeit', 'Zeitabstand', 'Läufe', 'Lauf ', nil,
	'Ereignis beenden?', 'nein', 'ja',
	'Startzeit'
}

local d = {}
if qs_readData(saveDir .. qs_getModelName() .. '.evt', d, 1) then
	evtActive, evtStart, evtDist, evtRuns = d[1], d[2], d[3], d[4]
end
d = nil

local lastRtc = 0
local lastMinute = 0
local blinkCnt = 0
local blink

local function display(groupNum, event, siteNum, iSel, lg, editMode, lcdCnt, chnStr, chnThr, valSrcStr, valSrcThr)
	lcdCnt = 0

	local floor = math.floor
	local glV6 = model.getGlobalVariable(6, 0)

	local rtc, x, y, w, h = getRtcTime() 
	local modelName = qs_getModelName()

	if rtc ~= lastRtc then blinkCnt = 0 lastRtc = rtc
	else blinkCnt = blinkCnt + 1 end
	blink = blinkCnt > 10 and true or false

	local function getText(n)							-- give the right word for selected language
		return words[lg * 31 - 31 + n] or words[n]
	end
	
	local function lZeroes(v)
		return v < 10 and '0'..v or ''..v
	end

	local function drawDualBar(x, y, w, h, out, src, rev)
		lcd.drawRectangle(x, y, w, h, FORCE)
		local h2 = h / 2
		lcd.drawLine(x + 1, y + h2, x + w - 2, y + h2, DOTTED ,FORCE)
		w = w / 2
		local xc = w + x
		w = w - 1.6
		if qs_rcCar.extendedLimits then lcd.drawPoint(xc - w / 1.5, y + 2 + h2, FORCE)
			lcd.drawPoint(xc + w / 1.5, y + 2 + h2, FORCE)
			if not src then lcd.drawPoint(xc - w / 1.5, y - 2 + h2, FORCE)
				lcd.drawPoint(xc + w / 1.5, y - 2 + h2, FORCE) end end
		lcd.drawLine(xc, y + 1, xc, y + h - 2, SOLID ,FORCE)
		out = out * w / (qs_rcCar.extendedLimits and 1536 or 1024)
		local src = not src and out or src * w / 1024
		if rev == 1 then out = -out end
		y = y + 1 for y = y, y + h2 - 2 do lcd.drawLine(xc, y, xc + src, y, SOLID, FORCE) end
		for y = y + h2, y + h2 + 2 do lcd.drawLine(xc, y, xc + out, y, SOLID, FORCE) end
	end

	local run, tm, txt, txt2, dist = 0, floor(rtc / 60), getText(26), '', 0
	if evtActive == 0 or tm >= (evtRuns - 1) * evtDist + evtStart then
		evtActive = 0 txt = getText(22) 
	else
		if tm >= evtStart then
			run = evtRuns - 1
			run = floor(run / (run * evtDist) * (tm - evtStart)) + 1
		end
		dist = (evtStart + run * evtDist) * 60 - rtc
		h = floor(dist / 3600)
		local m = floor((dist - h * 3600) / 60)
		local s = dist - h * 3600 - m * 60
		txt = txt .. run + 1 .. getText(27)
		if h > 0 then txt2 = txt2 .. h .. ':' end
		txt2 = txt2 .. lZeroes(m) .. ':' .. lZeroes(s)
		if m <= 5 and h + s == 0 and m ~= lastMinute then
			lastMinute = m
			if m > 0 then playNumber(m, 36) playFile('tostart.wav') end
		end
	end

	if siteNum == 2 or siteNum == 3 then
		local ts = rtc % 86400
		if siteNum == 2 and editMode > 1 then editMode = 1 end
		if siteNum == 3 then					-- draws year, month and weekday
			local dt = getDateTime()
			x, y = 0, 26	-- Draws Date
			drawText(x, y + 6, monthsWeekdays[lg * 19 - 18 + floor(rtc / 86400) % 7], BOLD)
			if lg == 1 then
				drawText(x, y + 14, monthsWeekdays[dt.mon + 7] .. ' ' .. dt.day .. '. ' .. dt.year, SMLSIZE)
			else
				drawText(x, y + 14, dt.day .. '. ' .. monthsWeekdays[lg * 19 - 12 + dt.mon] .. ' ' .. dt.year, SMLSIZE)
			end

			drawText(0, 23, txt, SMLSIZE + (iSel == 2 and INVERS or 0))
			drawText(lcd.getLastPos() + 3, 23, (dist < 120 and blink and '' or txt2), (dist < 120 and BOLD or SMLSIZE))

			if iSel == 3 then editMode = 1
			elseif iSel == 1 and editMode == 2 then 
				qs_clock = qs_clock == 0 and 1 or 0
				editMode = 3 qs_writeConf()
				qs_setPopup({getText(13), qs_clock == 0 and getText(14) or getText(15)})
			elseif iSel == 2 then
				tm = floor(ts / 60)
				if menue == 0 then
					if editMode == 2 then
						if evtActive == 0 then
							menue = 1 evtStart = tm
						else menue = 4 yn = 0 end
					end
				elseif menue == 1 then
					evtStart = qs_adjVal(evtStart, tm, 1440, getRotEncSpeed(), event)
					h = floor(evtStart / 60) local m = evtStart - h * 60
					qs_setPopup({getText(23), lZeroes(h)..':'..lZeroes(m)}, 1)
					if editMode == 3 then evtStart = floor(rtc / 86400) * 1440 + evtStart menue = 2 editMode = 2 end
				elseif menue == 2 then
					evtDist = qs_adjVal(evtDist, 1, 180, getRotEncSpeed(), event)
					h = floor(evtDist / 60) local m = evtDist - h * 60
					qs_setPopup({getText(24), lZeroes(h)..':'..lZeroes(m)}, 1)
					if editMode == 3 then menue = 3 editMode = 2 end
				elseif menue == 3 then
					evtRuns = qs_adjVal(evtRuns, 1, 20, getRotEncSpeed(), event)
					qs_setPopup({getText(25), evtRuns}, 1)
					if editMode == 3 then menue = 0 evtActive = -1 iSel = 1 lastMinute = 0 end
				elseif menue == 4 then
					yn = qs_adjVal(yn, 0, 1, getRotEncSpeed(), event, 800)
					qs_setPopup({getText(28), getText(yn + 29)}, 1)
					if editMode == 3 then menue = 0
						if yn == 1 then evtActive = -2 end
					end
				end
				if menue > 0 and editMode == 4 then menue = 0 end
			end
		end

		if evtActive < 0 then evtActive = evtActive + 2
			local f = io.open(saveDir .. modelName .. '.evt', 'w')
			local s = ', ' io.write(f, evtActive, s, evtStart, s, evtDist, s, evtRuns)
			io.close(f)
		end

		drehung = drehung < 360 and drehung + 1 or drehung - 360
		local turn = iSel == 3 and drehung or 0
		x, y = iSel == 3 and turn * .355 + 16 or 106, 14 -- Analog  Clock
		if qs_clock == 0 then
			qs_setAll(x, y, 0, 15)
			h = ts / 3600
			local s = ts - floor(h) * 3600
			local m = floor(s / 60)
			s = (s - m * 60) * 6
			drawText(x + 20, y - 1, h < 12 and 'A' or 'P', RIGHT + SMLSIZE)
			h = (h >= 12 and h - 12 or h) * 30
			for n = 0, 330, 30 do
				qs_setAngel(n + turn)
				if n % 90 == 0 then qs_gfRec(-1, -1, 1, n == 0 and 2 or 1, 1) else qs_line(0, 0, 0, 3) end
			end
			qs_setAngel(s + turn)
			qs_line(0, 2, 0, 17)
			qs_setAngel(m * 6 + turn)
			qs_line(0, 4, 0, 17)
			qs_setAngel(h + turn)
			qs_line(0, 7, 0, 17)
		else
			lcd.drawTimer(x + 5, y + 8, ts, TIMEHOUR + MIDSIZE + RIGHT)
		end
	end

	if siteNum == 4 then
		local timer = floor((iSel - 1) / 5)
		local func = (iSel - 1) % 5
		if editMode == 2 or editMode == 3 then
			if func == 0 then
				qs_drawTitel('Timer Name', MIDSIZE)
				editName = qs_inputText(editName, 3, editMode, event, '"?\\|/*<>:.')
				editMode = 2
				if event == evt_TELE_FIRST then
					local buffer = model.getTimer(timer)
					buffer.name, editMode = editName, 3
					model.setTimer(timer, buffer) end
				return editMode, lcdCnt, iSel, groupNum
			elseif func == 1 then
				qs_tmrDir[timer + 1] = qs_tmrDir[timer + 1] == 0 and 1 or 0
				qs_playSignal(qs_tmrDir[timer + 1] == 0 and 800 or 1200, 15)
				editMode = 3
			elseif func == 2 then
				model.resetTimer(timer)
				qs_playSignal(800, 15)
				editMode = 3
			elseif func == 3 then
				local buffer = model.getTimer(timer)
				buffer.mode = buffer.mode == 0 and 1 or 0
				model.setTimer(timer, buffer)
				playFile(buffer.mode == 0 and 'stop.wav' or 'start.wav')
				editMode = 3
			elseif func == 4 then
				local s = qs_adjVal(editValue, 0, 36000, getRotEncSpeed(), event, 800)
				if event == 110 then s = 0
				elseif event == 109 or event == 77 then s = s > 0 and s - 60 or s + 35940
				elseif event == 108 or event == 76 then s = s <= 35940 and s + 60 or s - 35940 end
				editValue = s
				local m = floor(s / 60)
				s = s - m * 60
				qs_setPopup({getText(31), lZeroes(m) .. ':' .. lZeroes(s), 'MDL/TELE', 'Minute +/-', 'SYS = 00:00'}, 1, 2)
		end end
		if editMode == 3 and func == 4 then
			local buffer = model.getTimer(timer)
			buffer.start = editValue
			model.setTimer(timer, buffer)
			model.resetTimer(timer)
		end
		for n = 0, 2 do
			local sel = n * 5 + 1
			local buffer = model.getTimer(n)
			local name = buffer.name
			if name == '' then name = 'TM' .. n + 1 end
			if editMode == 1 and n == timer then editValue, editName = buffer.start, name qs_inputText() end
			drawText(1, n * 12 + 13, name, BOLD + (iSel == sel and INVERS or 0))
			drawText(24, n * 12 + 14, qs_tmrDir[n + 1] == 0 and CHAR_DOWN or CHAR_UP, SMLSIZE + (iSel == sel + 1 and INVERS or 0))
			drawText(34, n * 12 + 14, 'Reset', SMLSIZE + (iSel == sel + 2 and INVERS or 0))
			drawText(74, n * 12 + 14, buffer.mode == 0 and 'Start' or 'Stop', SMLSIZE + CENTER + (iSel == sel + 3 and INVERS or 0))
			local value = qs_tmrDir[n + 1] == 0 and buffer.value or buffer.start - buffer.value
			lcd.drawTimer(value < 6000 and 127 or 120, n * 12 + 10, value, RIGHT + MIDSIZE + (iSel == sel + 4 and INVERS or 0))
		end
	end

	x, y, w, h = 19, 47, 91, 9 -- Mainbar with steering and throttle
	local sStr = valSrcStr
	local oStr = getOutputValue(chnStr)
	local sThr = valSrcThr
	local oThr = getOutputValue(chnThr)
	drawText(x, y + 1, getText(12)..chnStr + 1, RIGHT)
	drawText(x, y + h, getText(12)..chnThr + 1, RIGHT)
	lcd.drawNumber(x + w + 17, y + 1, (oStr < 0 and -oStr or oStr) / 10.24, RIGHT)
	lcd.drawNumber(x + w + 17, y + h, (oThr < 0 and -oThr or oThr) / 10.24, RIGHT)
	drawDualBar(x, y, w, h, oStr, sStr, model.getOutput(chnStr).revert)
	drawDualBar(x, y + h - 1, w, h, oThr, sThr, model.getOutput(chnThr).revert)
	if qs_skin % 8  >= 4 then
		lcd.drawFilledRectangle(x - 19, y, 19, h + h - 1, 0)
		lcd.drawFilledRectangle(x + w, y, 18, h + h - 1, 0)
	end
	local trim = model.getGlobalVariable(1, 0) * (w - 5) / 800
	x = x + w / 2
	for y = y + 3, y + 11, 8 do
		trim = trim < -43 and -43 or trim > 43 and 43 or trim
		local x2 = x + (trim < 0 and -1 or trim > 0 and 1 or 0) + trim
		for y = y, y + 1 do lcd.drawLine(x, y, x2, y, SOLID, FORCE) end
		trim = glV6 * (w - 5) / 800
	end
	if qs_skin % 16 >= 8 then lcd.drawFilledRectangle(19, 47, 91, 17, 0) end

	drawText(0, 2, modelName, 64) -- Draws the Head on the Mainscreen
	local modelNameX = 60 - lcd.getLastPos()
	local timer = model.getTimer(0).value
	if timer >= 0 or not blink then lcd.drawTimer(128, 2, timer, 64 + RIGHT) end
	local rs = getRSSI() / 10
	x, y = 62 - modelNameX * .66, 9
	for n = 2, 8, 2 do
		h = rs >= n and n or 1
		lcd.drawFilledRectangle(x, y - h, 2, h, FORCE)
		x = x + 3
	end

	local battMin = getGeneralSettings().battMin --Draws the Battery Symbol and the Voltage in percent
	local battVolt = getSourceValue(qs_sourceBat)
	local battPercent = math.ceil((battVolt - battMin) / (getGeneralSettings().battMax - battMin) * 100)
	battPercent = battPercent < 0 and 0 or battPercent > 100 and 100 or battPercent
	local battValue = math.ceil(battPercent * .13)
	qs_setAll(93 - modelNameX * .33, battValue > 0 and 1 or 2, 6, 9, battValue > 0 and 0 or 90, .5, 1)
	qs_gfRec(0, 0, 10, 14, 1, SOLID, ERASE)
	qs_gfRec(0, 0, 10, 14, 0)
	qs_line(2, -2, 8, -2)
	qs_line(2, -1, 8, -1)
	qs_gfRec(0, 14 - battValue, 10, 14, 1)
	drawText(93 - modelNameX * .33, 3, battPercent.."%", SMLSIZE + RIGHT)
	if battVolt <= battMin then qs_setPopup({getText(3)..battPercent.."%", getText(4)}) end

	if glV6 ~= trimThr and valSrcThr > -19 and valSrcThr < 19 then
		trimThr = glV6 qs_init(1) qs_init(1)
		qs_setPopup({getText(19), (glV6 < 0 and getText(20) or glV6 > 0 and getText(21) or '')..
		' '..string.format('%.1f', (glV6 < 0 and -glV6 or glV6) * .5)..'%'})
	end

	if siteNum < 4 then drawText(32, 13, qs_username, SMLSIZE + CENTER) end

	if siteNum == 1 or siteNum == 2 then  -- qs_items for 
		x, y, w = 1, 23, 63 -- print subtrim, steering rate, forward rate and brake rate
		drawText(x, y, getText(5), SMLSIZE)
		lcd.drawNumber(x + 32, y, model.getGlobalVariable(2, 0), SMLSIZE + RIGHT)
		drawText(x + 48, y, getText(6), SMLSIZE + (qs_ABS[1] == 1 and INVERS or 0))
		drawText(x, y + 8, getText(7), SMLSIZE)
		local trim = model.getGlobalVariable(1, 0) * .5
		drawText(x + 37, y + 8, trim < 0 and getText(8) or trim > 0 and getText(9) or '', SMLSIZE)
		lcd.drawNumber(x + w, y + 8, (trim < 0 and -trim or trim) * 10, SMLSIZE + RIGHT + PREC1)
		drawText(x, y + 16, getText(10), SMLSIZE)
		lcd.drawNumber(x + 31, y + 16, model.getGlobalVariable(0, 0),SMLSIZE + RIGHT)
		drawText(x + 32, y + 16, getText(11), SMLSIZE)
		lcd.drawNumber(x + w, y + 16, model.getGlobalVariable(3, 0),SMLSIZE + RIGHT)
		if qs_skin % 4 >= 2 then lcd.drawFilledRectangle(x - 1, y - 1, w + 1, 24, 0) end
	end

	if siteNum == 1 then
		x, y, w, h = 65, 13, 47, 9  -- Draws the other 4 channels
		local y1 = y
		local StB = qs_channelStB
		for i = 0, 5 do
			if i ~= chnStr and i ~= chnThr then
				drawText(x + 16, y1 + 2, getText(12)..i + 1, RIGHT + SMLSIZE)
				drawDualBar(x + 16, y1, w, h, getOutputValue(i), StB == i and sStr or nil, StB == i and 0 or nil) --model.getOutput(i).revert)
				y1 = y1 + h - 1
			end
		end
		if qs_skin % 2 >= 1 then lcd.drawFilledRectangle(x, y, 16, h * 4 - 3, 0) end
		if qs_skin % 16 >= 8 then lcd.drawFilledRectangle(81, 13, 47, 33, 0) end

		if editMode == 2 then
			qs_skin = qs_adjVal(qs_skin, 0, 31, floor((getRotEncSpeed() + 3) / 4), event)
			qs_setPopup({getText(18), qs_skin}) end
		if editMode > 2 then qs_setPopup() qs_writeConf() end
	end

	if siteNum == 5 then
		if qs_channelStB == -1 then
			qs_setPopup({'!|No setup for 4WS'}, 1)
			editMode = 1
		else
			local buffer = model.getOutput(qs_channelStB)
			local offset = buffer.offset
			local ws4Mode = qs_4wsMode
			drawText(0, 10, '4W-Steering', MIDSIZE)
			drawText(27, 22, 'Mode:', RIGHT)
			drawText(27, 30, 'Dir.:', RIGHT)
			drawText(27, 38, 'Trim:', RIGHT)
			drawText(29, 23, ws4Text[ws4Mode], SMLSIZE + (iSel == 1 and INVERS or 0))
			drawText(29, 31, qs_4wsRev == 0 and 'Normal' or 'Reverse', SMLSIZE + (iSel == 2 and INVERS or 0))
			drawText(29, 38, offset, iSel == 3 and INVERS or 0)
			if editMode == 2 then
				if iSel == 1 then
--					qs_4wsMode = qs_adjVal(ws4Mode, 1, 4, 1, event, 800)
--					qs_setPopup({'Steer-Mode', ws4Text[qs_4wsMode]}, 1)
--					if ws4Mode ~= qs_4wsMode then qs_init(1) ws4Mode = qs_4wsMode end
					qs_4wsMode = qs_adjVal(ws4Mode, 1, 4, 1, EVT_ROT_LEFT, 800)
					editMode = 3
					qs_init(1) ws4Mode = qs_4wsMode
				elseif iSel == 2 then
					qs_4wsRev = qs_4wsRev == 1 and 0 or 1
					qs_writeConf()
					qs_init(1)
					editMode = 3
				elseif iSel == 3 then
					buffer.offset = qs_adjVal(offset, -200, 200, getRotEncSpeed(), event)
					qs_setPopup({'Steer-Trim', buffer.offset}, 1)
					if offset ~= buffer.offset then model.setOutput(qs_channelStB, buffer) end
				end
			end
			local fLine, bLine = -3, 0
			if ws4Mode == 2 then bLine = 3
			elseif ws4Mode == 3 then fLine, bLine = 0, 3
			elseif ws4Mode == 4 then bLine = -3
			end
			local yF, yB = 0, 0
			if fLine ~= 0 then yF = 1 end
			if bLine ~= 0 then yB = 1 end
			for n = 0, 1 do
				lcd.drawLine(103 + fLine + n, 12 + yF, 103 - fLine + n, 20 - yF, SOLID, FORCE)
				lcd.drawLine(122 + fLine + n, 12 + yF, 122 - fLine + n, 20 - yF, SOLID, FORCE)
				lcd.drawLine(103 + bLine + n, 35 + yB, 103 - bLine + n, 43 - yB, SOLID, FORCE)
				lcd.drawLine(122 + bLine + n, 35 + yB, 122 - bLine + n, 43 - yB, SOLID, FORCE)
			end
			lcd.drawLine(103, 16, 123, 16, SOLID, FORCE)
			lcd.drawLine(103, 39, 123, 39, SOLID, FORCE)
			lcd.drawLine(113, 16, 113, 39, SOLID, FORCE)
		end
	end

	if siteNum == 6 then
		drawText(64, 40, getAvailableMemory(), SMLSIZE + CENTER)
	end

	if editMode == 1 then
		if event == evt_TELE_FIRST then groupNum = 2
		elseif event == evt_MDL_FIRST then groupNum = 3
		elseif event == evt_SYS_LONG then qs_ABS[1] = qs_ABS[1] == 0 and 1 or 0
			qs_setPopup({getText(6), qs_ABS[1] == 0 and getText(16) or getText(17)})
		end
	end

	return editMode, lcdCnt, iSel, groupNum
end
return display
-- return {display = display}
