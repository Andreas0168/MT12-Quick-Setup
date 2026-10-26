local secondLine = 0
local editValue = 0

local listFirst = qs_listFirst

if not listFirst[2020] then
	listFirst[2020] = 0
	listFirst[2030] = 0
end

local param = {}
local menueS1 = {}

local words = {
	'Steering', 'Forward', 'Brake', 													--  3
	'Rate', 'Trim', 'Expo', 'Endp. L', 'Endp. R', 								--  8
	'Str. back',																			--  9
	'Channel', 'Steering', 'Throttle', 'Direction', 'Endpoints & Trims',	-- 14
	'Speed-Settings',																		-- 15
	{'Steering out', 'Steering in', 'Forward', 'Brake',
	'Forward back', 'Brake back'}, 													-- 16
	{'ABS on', 'Audio-Feedback', 'ABS-PWM', 'Reduction first',
	'Trigger', 'Reduction', 'Cycles full', 'Cycles reduce',
	'PWM-Percent', 'Cycles minimum', 'Only on steer',
	'Steer. threshold',},																-- 17
	'Acceleration', {'Active', 'Forward', 'Brake'},								-- 19
	'Main Setup',																			-- 20
	'min:', 'max:',																		-- 22
	'This is only for', 'RadioLink R6FG Receiver',								-- 24
	{'VSC on', 'min. corn. speed'},													-- 25

	'Lenkung', 'Vorwärts', 'Bremse',
	nil, nil, nil, nil, nil,
	'Lnk. hint.',
	'Kanal', 'Lenkung', 'Gas', 'Richtung', 'Endpunkte & Trims',
	'Verzögerung',
	{'Lenkung raus', 'Lenkung rein', 'Vorwärts', 'Bremse',
	'Vorwärts zurück', 'Bremse zurück'},
	{'ABS an', 'Audio-Feedback', 'ABS-PWM', 'Zuerst reduziert',
	'Trigger', 'Reduktion', 'Zyklen voll', 'Zyklen reduziert',
	'PWM-Percent', 'Zyklen minimum', 'Nur beim lenken',
	'Lenkungsschwelle'},
	'Beschleunigung', {'Aktiviert', 'Vorwärts', 'Bremse'},
	nil,
	nil, nil,
	'Dies ist nur für', 'Radiolink R6FG Empfänger',
	{'VSC an', 'min. Kurveng.'}
}


local blinken = 0
local marker = 0

local function display(groupNum, event, siteNum, iSel, lg, editMode, lcdCnt, chnStr, chnThr, valSrcStr, valSrcThr) -- to setup your rc car
	local floor = math.floor
	local drawText = lcd.drawText
	local drawTitel = qs_drawTitel
	local drawList = qs_drawList
	local writeConf = qs_writeConf

	if editMode == 2 then blinken = blinken > 0 and blinken -1 or 20
		if event == EVT_ROT_LEFT or event == EVT_ROT_RIGHT then blinken = 20 end
	else blinken = 10 end
	marker = blinken > 8 and INVERS or 0

	local function getText(n)
		return words[qs_lang * 25 - 25 + n] or words[n]
	end

	local txtS1 = '11231239114544666478'
	local function getStdSetTxt(i)
		return getText(tonumber(string.sub(txtS1, i, i)))
	end

	local function drawDualBar(x, y, w, h, out, src, rev, trim)
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
		out = out * w / (qs_rcCar.extendedLimits and 1500 or 1000)
		if rev == 1 then out = -out end
		local src = not src and out or src * w / 1024
		y = y + 1 for y = y, y + h2 - 2 do lcd.drawLine(xc, y, xc + src, y, SOLID, FORCE) end
		for y = y + h2, y + h2 + 2 do lcd.drawLine(xc, y, xc + out, y, SOLID, FORCE) end
		if trim then
			trim = trim * w / 500
			trim = trim < -w and -w or trim > w and w or trim
			local x2 = xc + (trim < 0 and -1 or trim > 0 and 1 or 0) + trim
			for y = y + h2 - 2, y + h2 - 1 do lcd.drawLine(xc, y, x2, y, SOLID, FORCE) end
		end
	end

	local function channelText(i)
		if i == chnStr then return getText(11)
		elseif i == chnThr then return getText(12)
		elseif i == qs_chnStB then return getText(9)
		else return getText(10)..' '..i + 1 end
	end

	local function getSetParam(i, v)
		if v == nil then
			return i == 9 and -(model.getOutput(chnStr).min / 10) or
			i == 10 and model.getOutput(chnStr).max / 10 or
			model.getGlobalVariable(i - 1, qs_drvMode)
		else
			if i >= 9 then
				local out = model.getOutput(chnStr)
				if i == 9 then out.min = -(v * 10)
				else out.max = v * 10 end
				model.setOutput(chnStr, out)
			else
				model.setGlobalVariable(i - 1, qs_drvMode, v)
			end
		end
	end

	local function itemChg(site)
		iSel = (qs_chnStB == -1 and site > 7) and site -1 or site
		qs_oldVal = param[site]
	end

	local pX, pY = 35, -2
	local function drLine(x1, y1, x2, y2, p1, p2)
		lcd.drawLine(pX + x1, pY + y1, pX + x2, pY + y2, p1 or SOLID, p2 or FORCE)
	end

	local function drawRotRec(x, y, w, h, fill, rx, ry, rot, scale, p, f)
		qs_setAll(pX + x, pY + y, rx, ry, rot, scale or 1, 1)
		qs_gfRec(0.5, 0.5, w + .5, h + .5, fill, p, f)
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
			drLine(x + lastX, y - lastY, x + x1, y - y1, SOLID ,FORCE)
			if DBL == 1 then drLine(x - lastX, y + lastY + 1, x - x1, y + y1 + 1, SOLID ,FORCE) end
			lastX, lastY  = x1, y1
			x1 = x1 + 1
		end
	end

	-- Draws a box with a dotted vertical line in the mid and optional a expo curve
	local function drawExpoBox(x, y, w, h, expo, DBL, scale)
		local mx = floor(w / 2) + x
		lcd.drawRectangle(pX + x, pY + y, w, h, FORCE)
		drLine(x + mx, y, x + mx, y + h - 1, DOTTED, 0)
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
	local function expoRateStr(rate, output)
		local x, y, w = 0, 19, 45
		local my, eH = w / 2 + y, (w - 1) / 2
		local eH = (w - 1) / 2
		local expo = getSetParam(5)
		local scale = getSetParam(rate)
		local out = model.getOutput(output)
		scale = scale * ((-out.min / qs_MinMax[19] / 10 + out.max / qs_MinMax[19] / 10) / 2)
		local mx = drawExpoBox(x, y, w, w, expo, 1, scale)
		local y1 = getOutputValue(output) / (qs_MinMax[19] / 10 * 1.024)
		if model.getOutput(output).revert == 1 then y1 = -y1 end
		lcd.drawNumber(pX + x + w - 2, my + 4, y1, RIGHT)
		y1 = -(y1 * eH / 100)
		local x1 = valSrcStr * eH / 1024 + .5
		drLine(mx + x1 - 4, my + y1, mx + x1 + 4, my + y1, SOLID, FORCE)
		drLine(mx + x1, my + y1 - 4, mx + x1, my + y1 + 4, SOLID, FORCE)
	end

	-- Draws a box to display the rate and expo of forward and braking
	local function expoRateThr(brake)
		local expo = getSetParam(brake == 0 and 6 or 7)
		local scale = getSetParam(brake == 0 and 3 or 4)
		drawExpoBox(0, 19, 45, 45, expo, 0, scale)
		local y = 63 - getSetParam(brake == 0 and 3 or 4) * .44
		drLine(1, y, 44, y, DOTTED, FORCE)
		local x = valSrcThr
		if brake == 1 then x = -x end
		if x < 0 then x = 0 end
		x = x * .043945
		drLine(secondLine, 20, secondLine, 62, SOLID, FORCE)
		drLine(x, 20, x, 62, SOLID, FORCE)
		secondLine = x
	end

	local function strTrimEndp()
		pX = 25
		lcd.drawRectangle(pX, pY + 19, 66, 45, FORCE)
		local x = getOutputValue(chnStr)
		x = x < -7 and x or x > 7 and x or 0
		if model.getOutput(chnStr).revert == 1 then x = -x end
		drawRotRec(10, 21, 10, 40, 1, 8, 20, x * .02 + (x < -5 and x * .005 or 0))
		drawRotRec(45, 21, 10, 40, 1, 2, 20, x * .02 + (x > 5 and x * .005 or 0))
		drLine(15, 20, 15, 60, DOTTED, 0)
		drLine(50, 20, 50, 60, DOTTED, 0)
	end

	if siteNum == 1 then  -- menue for the most standard setup
		if editMode == 1 then
			for n = 1, 10 do menueS1[n] = getStdSetTxt(n)..' '..getStdSetTxt(n + 10) end
			for n = 1, 10 do param[n] = getSetParam(n) end
		end
		local disp, pointer = qs_chnStB == -1 and '+++++++ ++' or '++++++++++', 0
		editMode, pointer = drawList(getText(20), iSel, menueS1, event, 5, 14, 10, 64, param, '%P%%%%%%%%',
		qs_MinMax, editMode, disp, {1, 1}, 4)
		if editMode == 4 then param[pointer] = qs_oldVal editMode = 3 end
		if editMode == 3 then
			for n = 1, 10 do getSetParam(n, param[n]) end
		elseif editMode == 2 then
			lcd.drawFilledRectangle(0, 12, 95, 52, ERASE)
			qs_drawTitel(menueS1[pointer], MIDSIZE)
			getSetParam(pointer, param[pointer])
			if pointer == 1 then
				expoRateStr(1, chnStr)
				if event == evt_PAGER_FIRST then itemChg(2) end
			elseif pointer == 2 then
				strTrimEndp()
				if event == evt_PAGER_FIRST then itemChg(5) end
			elseif pointer == 3 then
				expoRateThr(0)
				if valSrcThr < -500 or event == evt_PAGER_FIRST then itemChg(4) end
			elseif pointer == 4 then
				expoRateThr(1)
				if valSrcThr > 500 then itemChg(3)
				elseif event == evt_PAGER_FIRST then itemChg(6) end
			elseif pointer == 5 then
				expoRateStr(1, chnStr)
				if event == evt_PAGER_FIRST then itemChg(qs_chnStB == -1 and 1 or 8) end
			elseif pointer == 6 then
				expoRateThr(0)
				if valSrcThr < -500 then itemChg(7)
				elseif event == evt_PAGER_FIRST then itemChg(7) end
			elseif pointer == 7 then
				expoRateThr(1)
				if valSrcThr > 500 then itemChg(6)
				elseif event == evt_PAGER_FIRST then itemChg(3) end
			elseif pointer == 8 then
				expoRateStr(8, qs_chnStB)
				if event == evt_PAGER_FIRST then itemChg(1) end
			elseif pointer == 9 or pointer == 10 then
				strTrimEndp()
				if pointer == 9 and valSrcStr > 500 then itemChg(10)
				elseif pointer == 10 and valSrcStr < -500 then itemChg( 9) end
			end
		end

	elseif siteNum == 2 then  -- site to setup revers on each channel
		param = {}
		drawTitel(getText(13), MIDSIZE)
		if editMode == 2 then
			local output = model.getOutput(iSel - 1)
			output.revert = 1 - output.revert
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

	elseif siteNum == 3 then  -- setup endpoints and trims for each channel
		local limit, val, oldVal = qs_rcCar.extendedLimits and 1500 or 1000, 0, 0
		drawTitel(getText(14), MIDSIZE)
		local y, lf = 14, listFirst[2030]
		if iSel - 1 < lf then lf = floor((iSel - 1) / 4) * 4
		elseif iSel - 12 > lf then lf = floor((iSel - 9) / 4) * 4 end
		listFirst[2030] = lf
		lf = floor(lf / 4)
		for chn = lf, lf + 2 do
			local lL, lR = 'L', 'H'
			if chn == chnThr then lL, lR = 'B', 'F'
			elseif chn == chnStr or chn == qs_chnStB then lR = 'R' end
			lcd.drawText(0, y + 8, lL)
			lcd.drawText(127, y + 8, lR, RIGHT)
			local output = model.getOutput(chn)
			local glV = chn == chnStr and 1 or chn == chnThr and 4 or -1
			local trim = glV == -1 and (output.offset) or qs_glVars[glV]
			drawDualBar(6, y + 8, 113, 7, getOutputValue(chn), nil, output.revert, trim)
			drawText(63, y, channelText(chn), BOLD + CENTER)
			for n = 1, 4 do
				local mark = chn * 4 + n
				val = n == 1 and -output.min or n == 2 and output.max or n == 3 and trim or output.ppmCenter
				if iSel == mark then
					if editMode == 1 then editValue = val
					elseif editMode == 4 then val = editValue
					elseif editMode == 2 then
						val, oldVal = qs_adjVal(val, n == 3 and -1000 or n == 4 and -500 or 0, n == 3 and 1000 or n == 4 and 500 or limit, getRotEncSpeed(), event) end
					if (val ~= oldVal and editMode == 2) or editMode == 4 then
						if n == 3 then if glV == -1 then output.offset = val else model.setGlobalVariable(glV == 4 and 8 or glV, qs_drvMode, val) end
						elseif n == 4 then output.ppmCenter = val
						elseif n == 1 then output.min = -val else output.max = val end
						model.setOutput(chn, output) end end
				if mark == iSel and n > 2 then
					lcd.drawText(127, y, n == 3 and '         Trim:       ' or '  PPM-Center:       ', RIGHT + BOLD)
					lcd.drawNumber(127, y, n == 3 and val or val + 1500, BOLD + PREC1 + RIGHT + marker)
				else lcd.drawNumber(n * 99 - 99 + 28, y, val, BOLD + PREC1 + RIGHT + (mark == iSel and marker or 0)) end end
			y = y + 17
		end
		lcdCnt = 0

	-- elseif siteNum == 3 then  -- setup endpoints and trims for each channel
		-- local limit, val, oldVal = qs_rcCar.extendedLimits and 1500 or 1000, 0, 0
		-- drawTitel(getText(14), MIDSIZE)
		-- local y, lf = 14, listFirst[2030]
		-- if iSel - 1 < lf then lf = floor((iSel - 1) / 4) * 4
		-- elseif iSel - 12 > lf then lf = floor((iSel - 9) / 4) * 4 end
		-- listFirst[2030] = lf
		-- lf = floor(lf / 4)
		-- for chn = lf, lf + 2 do
			-- local lL, lR = 'L', 'H'
			-- if chn == chnThr then lL, lR = 'B', 'F'
			-- elseif chn == chnStr or chn == qs_chnStB then lR = 'R' end
			-- lcd.drawText(0, y + 8, lL)
			-- lcd.drawText(127, y + 8, lR, RIGHT)
			-- local output = model.getOutput(chn)
			-- local glV = chn == chnStr and 1 or chn == chnThr and 4 or -1
			-- local trim = glV == -1 and (output.offset) or qs_glVars[glV]
			-- drawDualBar(6, y + 8, 113, 7, getOutputValue(chn), nil, output.revert, trim)
			-- drawText(63, y, channelText(chn), BOLD + CENTER)
			-- for n = 0, 3 do
				-- local mark = chn * 4 + n + 1
				-- val = n == 0 and -output.min or n == 1 and output.max or n == 2 and trim or output.ppmCenter
				-- if iSel == mark then
					-- if editMode == 1 then editValue = val
					-- elseif editMode == 4 then val = editValue
					-- elseif editMode == 2 then
						-- val, oldVal = qs_adjVal(val, n == 2 and -1000 or n == 3 and -500 or 0, n == 2 and 1000 or n == 3 and 500 or limit, getRotEncSpeed(), event) end
					-- if (val ~= oldVal and editMode == 2) or editMode == 4 then
						-- if n == 2 then if glV == -1 then output.offset = val else model.setGlobalVariable(glV == 4 and 8 or glV, qs_drvMode, val) end
						-- elseif n == 3 then output.ppmCenter = val
						-- elseif n == 0 then output.min = -val else output.max = val end
						-- model.setOutput(chn, output) end end
				-- if mark == iSel and n > 1 then
					-- lcd.drawText(127, y, n == 2 and '         Trim:       ' or '  PPM-Center:       ', RIGHT + BOLD)
					-- lcd.drawNumber(127, y, n == 2 and val or val + 1500, BOLD + PREC1 + RIGHT + marker)
				-- else lcd.drawNumber(n * 99 + 28, y, val, BOLD + PREC1 + RIGHT + (mark == iSel and marker or 0)) end end
			-- y = y + 17
		-- end
		-- lcdCnt = 0

	elseif siteNum == 4 then  -- speed setting to slow down steering, forward and brake
		local mixStrL = model.getMix(chnStr, 0)
		local mixStrR = model.getMix(chnStr, 1)
		local mixFwd = model.getMix(chnThr, 0)
		local mixBrk = model.getMix(chnThr, 1)
		if editMode == 1 then
			param = {mixStrL.speedDown, mixStrL.speedUp, mixFwd.speedUp, mixBrk.speedDown, mixFwd.speedDown, mixBrk.speedUp}
		end
		editMode = drawList(getText(15), iSel, getText(16), event, 5, 14, 10, 64, param,
		'SSSSSS', {0, 0, 0, 0, 0, 0,   50, 50, 50, 50, 50, 50}, editMode, nil, {2, 2, 2, 2, 2, 2})
		if editMode == 3 then
			mixStrL.speedDown = param[1] mixStrR.speedUp = param[1] 
			mixStrL.speedUp = param[2] mixStrR.speedDown = param[2]
			mixFwd.speedUp = param[3]
			mixBrk.speedDown = param[4]
			mixFwd.speedDown = param[5]
			mixBrk.speedUp = param[6]
			model.deleteMix(chnStr, 0) model.insertMix(chnStr, 0, mixStrL) model.deleteMix(chnStr, 1) model.insertMix(chnStr, 1, mixStrR)
			model.deleteMix(chnThr, 0) model.insertMix(chnThr, 0, mixFwd)
			model.deleteMix(chnThr, 1) model.insertMix(chnThr, 1, mixBrk)
			if qs_chnStB ~= -1 then
				mixStrL = model.getMix(qs_chnStB, 0)
				mixStrR = model.getMix(qs_chnStB, 1)
				mixStrL.speedDown = param[1] mixStrR.speedUp = param[1] 
				mixStrL.speedUp = param[2] mixStrR.speedDown = param[2]
				model.deleteMix(qs_chnStB, 0) model.insertMix(qs_chnStB, 0, mixStrL) model.deleteMix(qs_chnStB, 1) model.insertMix(qs_chnStB, 1, mixStrR) 
			end
		end

	elseif siteNum == 5 then		-- setup VSC-System
		editMode, editValue = drawList('VSC-System', iSel, getText(25), event, 2, 20, 14, 64, qs_VSC, '|%',
		{0, 20,  1, 99}, editMode, nil, {1, .01})
		if editMode == 3 then writeConf() end

	elseif siteNum == 6 then		-- setup ABS-System
		local disp = qs_ABS[3] == 0 and '++++++++  ++' or '++++++  ++++'
		editMode = drawList('ABS-System', iSel, getText(17), event, 5, 14, 10, 64, qs_ABS, '||||%%--% |%',
		{0, 0, 0, 0, 10, 10, 1, 1, 1, 1, 0, 0,  1, 1, 1, 1, 100, 100, 20, 20, 100, 20, 1, 100}, editMode, disp, {1, 1, 1, 1, -10.24, .01})
		if editMode == 3 then writeConf() end

	elseif siteNum == 7 then		-- setup ACC-System
		editMode = drawList(getText(18), iSel, getText(19), event, 3, 20, 14, 64, qs_ACC, '|%%',
		{0, 0, 0,   1, 100, 100}, editMode, nil, {1, .05, .05})
		if editMode == 3 then writeConf()
			local accFwd = qs_ACC[1] == 0 and 0 or qs_ACC[2] * 10
			local accBrk = qs_ACC[1] == 0 and 0 or -(qs_ACC[3] * 10)
			for n = 0, 1 do
				if iSel == 1 or iSel == n + 2 then
					local mix = model.getMix(chnThr, n) mix.offset = n == 0 and accFwd or accBrk
					model.deleteMix(chnThr, n) model.insertMix(chnThr, n, mix) 
				end
			end
		end

	elseif siteNum == 8 then
		local output = model.getOutput(7)
		local p = {(output.offset + 1000)}
		editMode = drawList('Gyro Setup', iSel, {'Gyro Gain'}, event,
		1, 30, 14, MIDSIZE, p, '%', {0,   100}, editMode, nil, {20})
		local t = p[1] - 1000
		if t ~= output.offset then output.offset = t model.setOutput(7, output) end
		for n = 0, 1 do drawText(64, n * 8 + 48, getText(n + 23), SMLSIZE + CENTER) end
	end

	if editMode == 1 then
		if event == evt_MDL_FIRST then qs_popGroup() groupNum = 3 end
		if event == evt_TELE_FIRST then qs_popGroup() groupNum = 1 end
	end

	-- lcd.drawNumber(0, 14, getAvailableMemory(), MIDSIZE)

	return editMode, lcdCnt, iSel, groupNum
end
return display
