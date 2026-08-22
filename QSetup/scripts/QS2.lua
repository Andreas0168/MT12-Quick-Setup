local evt_PAGER_FIRST = 101
local evt_MDL_FIRST = 108

local secondLine = 0
local editValue = 0

local listFirst = qs_listFirst

if not listFirst[2010] then
	listFirst[2010] = 1
	listFirst[2020] = 0
	listFirst[2030] = 0
	listFirst[2040] = 1
end

local words = {
	'Steering', 'Forward', 'Brake', 												--  3
	'Rate', 'Trim', 'Expo', 'Endp. L', 'Endp. R', 							--  8
	'Forward', 																			--  9
	'Channel', 'Steering', 'Throttle', 'Direction', 'Endpoints', 		-- 14
	'Steering out:', 'Steering in:', 'Forward:', 'Brake:', 				-- 18
	'Forward back:', 'Brake back:', 												-- 20
	'ABS on', 'Audio-Feedback', 'ABS-PWM', 'Reduction first',			-- 24
	'Trigger', 'Reduction', 'Cycles full', 'Cycles reduce',				-- 28
	'PWM-Percent', 'Cycles minimum',												-- 30
	'Acceleration', 'Active', 'Forward', 'Brake',							-- 34
	'Basic setup',																		-- 35
	'min:', 'max:',																	-- 37
	'Speed-Settings',																	-- 38
	'This is only for', 'RadioLink R6FG Receiver'							-- 40
	,
	'Lenkung', 'Vorw.', 'Bremse',
	nil, nil, nil, nil, nil,
	'Vorwärts',
	'Kanal', 'Lenkung', 'Gas', 'Richtung', 'Endpunkte',
	'Lenkung raus:', 'Lenkung rein:', 'Vorwärts:', 'Bremse:',
	'Vorw. zurück:', 'Bremse zurück:',
	'ABS an', nil, nil, 'Zuerst reduziert',
	nil, 'Reduktion', 'Zyklen voll', 'Zyklen reduziert',
	nil, 'Zyklen minimum',
	'Beschleunigung', 'Aktiviert', 'Vorwärts', 'Bremse',
	'Das Wichtigste',
	nil, nil,
	'Verzögerung',
	'Dies ist nur für', 'Radiolink R6FG Empfänger'
}


-- local paramA = '012345ab8'

local function display(groupNum, event, siteNum, iSel, lg, editMode, lcdCnt, chnStr, chnThr, valSrcStr, valSrcThr) -- to setup your rc car
	local floor = math.floor
	local drawText = lcd.drawText
	local drawTitel = qs_drawTitel
	local drawList = qs_drawList

	local function getText(n)
		return words[lg * 40 - 40 + n] or words[n]
	end

	local function getSetParam(i, v)
		-- i = string.sub(paramA, i, i)
		-- if v == nil then
			-- if i == 'a' then return -(model.getOutput(chnStr).min / 10)
			-- elseif i == 'b' then return model.getOutput(chnStr).max / 10
			-- else return model.getGlobalVariable(toNum(i), 0)
			-- end
		-- else
			-- local out
			-- if i == 'a' or i == 'b' then out = model.getOutput(chnStr)
				-- if i == 'a' then out.min = -(v * 10)
				-- elseif i == 'b' then out.max = v * 10
				-- end
			-- model.setOutput(chnStr, out)
			-- else model.setGlobalVariable(toNum(i), 0, v)
			-- end
		-- end
	-- end

		if v == nil then
			if i == 7 then return -(model.getOutput(chnStr).min / 10)
			elseif i == 8 then return model.getOutput(chnStr).max / 10
			else return model.getGlobalVariable(i - 1, 0)
			end
		else
			local out
			if i == 7 or i == 8 then out = model.getOutput(chnStr)
				if i == 7 then out.min = -(v * 10)
				elseif i == 8 then out.max = v * 10
				end
				model.setOutput(chnStr, out)
			else model.setGlobalVariable(i - 1, 0, v)
			end
		end
	end

	local function itemChg(site)
		iSel = site
		editValue = getSetParam(iSel)
	end

	local function drawRotRec(x, y, w, h, fill, rx, ry, rot, scale, p, f)
		qs_setAll(x, y, rx, ry, rot, scale or 1, 1)
		qs_gfRec(0.5, 0.5, w + .5, h + .5, fill, p, f)
	end

	local function channelText(i)
		if i == chnStr then return getText(11)
		elseif i == chnThr then return getText(12)
		else return getText(10)..' '..i + 1 end
	end

	local function drawExpo(expo, DBL, x, y, Height, scale)
		local lastX, lastY = 0, 0
		expo = expo * .04
		scale = scale * .01
		if expo == 0 then expo = .01 end
		local Start = expo < 0 and -1 or 0
		local x1 = 0
		local ex = expo < 0 and -expo or expo
		local ymax = math.sinh(ex)
		for xd = Start, Start + 1 - 1 / Height, 1 / Height do
			local y1 = math.sinh(xd * ex)
			y1 = y1 * Height / ymax
			y1 = y1 - .5
			if expo < 0 then y1 = y1 + Height end
			y1 = y1 * scale
			lcd.drawLine(x + lastX, y - lastY, x + x1, y - y1, SOLID ,FORCE)
			if DBL == 1 then lcd.drawLine(x - lastX, y + lastY + 1, x - x1, y + y1 + 1, SOLID ,FORCE) end
			lastX, lastY  = x1, y1
			x1 = x1 + 1
		end
	end

	-- Draws a box with a dotted vertical line in the mid and optional a expo curve
	local function drawExpoBox(x, y, w, h, expo, DBL, scale)
		local mx = floor(w / 2) + x
		lcd.drawRectangle(x, y, w, h, FORCE)
		lcd.drawLine(x + mx, y, x + mx, y + h - 1, DOTTED, 0)
		local my = floor(h / 2) + y
		if expo == nil then return mx end
		drawExpo(expo, DBL,
			DBL == 1 and mx or x,
			DBL == 1 and my or y + h - 1,
			DBL == 1 and floor(w / 2) or w - 1,
			scale)
		return mx
	end

	-- Draws a box to display the rate and expo for steering and draws a crosshair on the output line
	local function expoRateStr()
		local x = 0
		local y = 19
		local w = 45
		local my = w / 2 + y
		local eH = (w - 1) / 2
		local expo = getSetParam(5)
		local scale = getSetParam(1)
		local mx = drawExpoBox(x, y, w, w, expo, 1, scale)
		local y1 = getOutputValue(chnStr) / 10.24
		if model.getOutput(chnStr).revert == 1 then y1 = -y1 end
		lcd.drawNumber(x + w - 2, my + 4, y1, RIGHT)
		y1 = -(y1 * eH / 100)
		local x1 = valSrcStr * eH / 1024 + .5
		lcd.drawLine(mx + x1 - 4, my + y1, mx + x1 + 4, my + y1, SOLID, FORCE)
		lcd.drawLine(mx + x1, my + y1 - 4, mx + x1, my + y1 + 4, SOLID, FORCE)
	end

	-- Draws a box to display the rate and expo of forward and braking
	local function expoRateThr(brake)
		local expo = getSetParam(brake == 0 and 6 or 9)
		local scale = getSetParam(brake == 0 and 3 or 4)
		drawExpoBox(0, 19, 45, 45, expo, 0, scale)
		local y = 63 - getSetParam(brake == 0 and 3 or 4) * .44
		lcd.drawLine(1, y, 44, y, DOTTED, FORCE)
		local x = valSrcThr
		if brake == 1 then x = -x end
		if x < 0 then x = 0 end
		x = x * .043945
		lcd.drawLine(secondLine, 20, secondLine, 62, SOLID, FORCE)
		lcd.drawLine(x, 20, x, 62, SOLID, FORCE)
		secondLine = x
	end

local function getStdSetTxt(i)
	local siteStdSetTxt = '112312113454466786119319113'
	return getText(tonumber(string.sub(siteStdSetTxt, i, i)))
end

	if siteNum == 1 then  -- menue for the most standard setup
		if editMode == 4 then
			getSetParam(iSel, editValue)
		elseif editMode == 1 then
			editValue = getSetParam(iSel)
			local lf = listFirst[2010]
			if iSel < lf then lf = floor((iSel - 1) / 2) * 2 + 1
			elseif iSel - 7 > lf then lf = floor((iSel - 7) / 2) * 2 + 1 end
			listFirst[2010] = lf
			local x, y, first, last = 0, 1, lf - 1, lf + 7
			if last > 9 then last = 9 end
			for i = first + 1, last do
				lcd.drawNumber(x + (x == 0 and 63 or 64), y + 1, getSetParam(i),
				RIGHT + MIDSIZE + (i == 2 and PREC1 or 0) + (i == iSel and INVERS or 0))
				drawText(x, y, getStdSetTxt(i), SMLSIZE)
				drawText(x, y + 7, getStdSetTxt(i + 9)..':', SMLSIZE)
				x = x + 64 if x > 127 then x = 0 y = y + 16 end
			end
		elseif editMode == 2 then
			getSetParam(iSel, qs_adjVal(getSetParam(iSel),qs_MinMax[iSel],qs_MinMax[iSel + 9],getRotEncSpeed(),event))
			lcd.drawNumber(129, 22, getSetParam(iSel), RIGHT + XXLSIZE + (iSel == 2 and PREC1 or 0))
			drawText(0, 4, getStdSetTxt(iSel + 18)..' '..getStdSetTxt(iSel + 9)..':', MIDSIZE)
			if iSel == 1 then
				expoRateStr()
				if event == evt_PAGER_FIRST then itemChg(2) end
			elseif iSel == 2 then
				local x = getOutputValue(chnStr)
				x = x < -7 and x or x > 7 and x or 0
				if model.getOutput(chnStr).revert == 1 then x = -x end
				drawRotRec(11, 21, 10, 40, 1, x < -7 and 8 or x > 7 and 2 or 5, 20, x * .02)
				drawExpoBox(0, 19, 33, 45)
				-- lcd.drawLine(mx + x, 19, mx - x, 63, SOLID ,FORCE)
				if event == evt_PAGER_FIRST then itemChg(5) end
			elseif iSel == 3 then
				expoRateThr(0)
				if valSrcThr < -500 or event == evt_PAGER_FIRST then itemChg(4) end
			elseif iSel == 4 then
				expoRateThr(1)
				if valSrcThr > 500 then itemChg(3)
				elseif event == evt_PAGER_FIRST then itemChg(6) end
			elseif iSel == 5 then
				expoRateStr()
				if event == evt_PAGER_FIRST then itemChg(1) end
			elseif iSel == 6 then
				expoRateThr(0)
				if valSrcThr < -500 then itemChg(9)
				elseif event == evt_PAGER_FIRST then itemChg(9) end
			elseif iSel == 7 or iSel == 8 then
				lcd.drawRectangle(0, 19, 56, 45, FORCE)
				local x = getOutputValue(chnStr)
				x = x < -7 and x or x > 7 and x or 0
				if model.getOutput(chnStr).revert == 1 then x = -x end
				drawRotRec(10, 21, 10, 40, 1, 8, 20, x * .02 + (x < -5 and x * .005 or 0))
				drawRotRec(35, 21, 10, 40, 1, 2, 20, x * .02 + (x > 5 and x * .005 or 0))
				lcd.drawLine(15, 20, 15, 60, DOTTED, 0)
				lcd.drawLine(40, 20, 40, 60, DOTTED, 0)
				if iSel == 7 and valSrcStr > 500 then itemChg(8)
				elseif iSel == 8 and valSrcStr < -500 then itemChg(7) end
			elseif iSel == 9 then
				expoRateThr(1)
				if valSrcThr > 500 then itemChg(6)
				elseif event == evt_PAGER_FIRST then itemChg(3) end
			end
		end

	elseif siteNum == 2 then  -- site to setup revers on each channel
		drawTitel(getText(13), MIDSIZE)
		if editMode == 2 then
			local output = model.getOutput(iSel - 1)
			output.revert = output.revert == 0 and 1 or 0
			model.setOutput(iSel - 1, output)
			editMode = 1
			qs_playSignal(output.revert == 0 and 800 or 1200, 30)
			qs_init(1)
		end
		local x, y, lf = 49, 14, listFirst[2020]
		if iSel - 1 < lf then lf = floor((iSel - 1) / 2) * 2
		elseif iSel - 8 > lf then lf = floor((iSel - 7) / 2) * 2 end
		listFirst[2020] = lf
		for i = lf, lf + 7 do
			drawText(x - 1, y + 2, channelText(i), RIGHT + SMLSIZE)
			if iSel - 1 == i then
				lcd.drawRectangle(x - 1, y - 1, 16, 12, FORCE)
			end
			lcd.drawRectangle(x, y, 14, 10, FORCE)
			local x1 = model.getOutput(i).revert * 5 + x + 2
			lcd.drawFilledRectangle(x1, y + 2, 5, 6, FORCE)
			x = x + 64 if x > 127 then x = 49 y = y + 13 end
		end

	elseif siteNum == 3 then  -- setup endpoints for each channel
		if editMode == 2 or editMode == 4 then
			local chn = floor((iSel - 1) / 2)
			local MinMax = floor(iSel / 2 - chn)
			local output = model.getOutput(chn)
			local val = MinMax == 0 and output.min or output.max
			if editMode == 4 then val = editValue end
			local limit = qs_rcCar.extendedLimits and 1500 or 1000
			val = qs_adjVal(val, MinMax == 0 and -limit or 0, MinMax == 0 and 0 or limit, getRotEncSpeed(), event)
			if MinMax == 0 then output.min = val else output.max = val end
			model.setOutput(chn, output)
			lcd.drawNumber(129, 22, val, RIGHT + XXLSIZE + PREC1)
			if chn == chnThr then
				drawText(0, 4, MinMax == 0 and (getText(3)..' '..getText(36)) or (getText(12)..' '..getText(37)), MIDSIZE)
			else
				drawText(0, 4, channelText(chn)..' '..(MinMax == 0 and getText(36) or getText(37)), MIDSIZE)
			end
		elseif editMode == 1 then
			drawTitel(getText(14), MIDSIZE)
			local y, lf = 13, listFirst[2030]
			if iSel - 1 < lf then lf = floor((iSel - 1) / 2) * 2
			elseif iSel - 6 > lf then lf = floor((iSel - 5) / 2) * 2 end
			listFirst[2030] = lf
			local first = floor(lf / 2)
			for i = first, first + 2 do
				if i == chnThr then
					drawText(75, y + 1, getText(3), RIGHT)
					drawText(75, y + 9, getText(12), RIGHT)
				else drawText(75, y + 3, channelText(i), MIDSIZE + RIGHT) end
				for n = 0, 1 do
					local mark = i * 2 + n + 1
					local val = n == 0 and model.getOutput(i).min or model.getOutput(i).max
					drawText(99, n * 8 + y + 1, n == 0 and getText(36) or getText(37), RIGHT)
					lcd.drawNumber(128, n * 8 + y + 1, val, PREC1 + RIGHT + (mark == iSel and INVERS or 0))
					if iSel == mark then editValue = val end
				end
				y = y + 17
			end
		end

	elseif siteNum == 4 then  -- speed setting to slow down steering, forward and brake
		local mixStrL = model.getMix(chnStr, 0)
		local mixStrR = model.getMix(chnStr, 1)
		local mixFwd = model.getMix(chnThr, 0)
		local mixBrk = model.getMix(chnThr, 1)
		if editMode == 1 then
			drawTitel(getText(38), MIDSIZE)
			local y, lf = 13, listFirst[2040]
			if iSel < lf then lf = iSel elseif iSel - 3 > lf then lf = iSel - 3 end
			listFirst[2040] = lf
			for i = lf, lf + 3 do
				local val = (i == 1 and mixStrL.speedDown or i == 2 and mixStrL.speedUp or
					i == 3 and mixFwd.speedUp or i == 4 and mixBrk.speedDown or
					i == 5 and mixFwd.speedDown or mixBrk.speedUp) * 5
				if i == iSel then editValue = val end
				drawText(128, y + 3, getText(14 + i)..'            s', RIGHT)
				lcd.drawNumber(121, y, val, RIGHT + MIDSIZE + PREC2 + (iSel == i and INVERS or 0))
				y = y + 13
			end
		elseif editMode == 2 then
			editValue = qs_adjVal(editValue, 0, 1250, 5 * getRotEncSpeed(), event)
			lcd.drawNumber(114, 22, editValue, RIGHT + XXLSIZE + PREC2)
			drawText(128, 44, 'S', DBLSIZE + RIGHT)
			drawText(0, 4, getText(14 + iSel), MIDSIZE)
		elseif editMode == 3 then
			editValue = editValue / 5
			if iSel == 1 then mixStrL.speedDown = editValue mixStrR.speedUp = editValue 
			elseif iSel == 2 then mixStrL.speedUp = editValue mixStrR.speedDown = editValue
			elseif iSel == 3 then mixFwd.speedUp = editValue
			elseif iSel == 4 then mixBrk.speedDown = editValue
			elseif iSel == 5 then mixFwd.speedDown = editValue
			elseif iSel == 6 then mixBrk.speedUp = editValue
			end
			if iSel < 3 then model.deleteMix(chnStr, 0) model.deleteMix(chnStr, 0) 
				model.insertMix(chnStr, 0, mixStrR) model.insertMix(chnStr, 0, mixStrL)
			elseif iSel == 3 or iSel == 5 then model.deleteMix(chnThr, 0) model.insertMix(chnThr, 0, mixFwd)
			elseif iSel == 4 or iSel == 6 then model.deleteMix(chnThr, 1) model.insertMix(chnThr, 1, mixBrk)
			end
		end

	elseif siteNum == 5 then		-- setup ABS-System
		local ABS, text = qs_ABS, {}
		for n = 1, 10 do text[n] = getText(n + 20) end
		local v = iSel + (iSel > 6 and ABS[3] * 2 or 0)
		local disp = ABS[3] == 0 and '++++++++' or '++++++  ++'
		editMode = drawList('ABS-System', iSel, text, event, 5, 14, 10, 64, ABS, '||||%%--% ',
		{0, 0, 0, 0, 10, 10, 1, 1, 1, 1,   1, 1, 1, 1, 100, 100, 20, 20, 100, 20}, editMode, disp, {1, 1, 1, 1, -10.24, .01})
		if editMode == 1 then editValue = ABS[v]
		elseif editMode == 3 and editValue ~= ABS[v] then qs_writeConf()
		elseif editMode == 4 then ABS[v] = editValue end

	elseif siteNum == 6 then
		local ACC = qs_ACC
		editMode = drawList(getText(31), iSel, {getText(32), getText(33), getText(34)}, event,
		3, 20, 14, 64, ACC, '|%%', {0, 0, 0,   1, 100, 100}, editMode, nil, {1, .05, .05})
		if editMode == 1 then editValue = ACC[iSel]
		elseif editMode == 3 and editValue ~= ACC[iSel] then qs_writeConf()
		elseif editMode == 4 then ACC[iSel] = editValue end

	elseif siteNum == 7 then
		local output = model.getOutput(7)
		local p = {(output.offset + 1000)}
		editMode = drawList('Gyro Setup', iSel, {'Gyro Gain'}, event,
		1, 30, 14, MIDSIZE, p, '%', {0,   100}, editMode, nil, {20})
		local t = p[1] - 1000
		if t ~= output.offset then output.offset = t model.setOutput(7, output) end
		for n = 0, 1 do drawText(64, n * 8 + 48, getText(n + 39), SMLSIZE + CENTER) end

	end

	if event == evt_MDL_FIRST and editMode == 1 then qs_popGroup() groupNum = 3 end

	return editMode, lcdCnt, iSel, groupNum
end
return display
