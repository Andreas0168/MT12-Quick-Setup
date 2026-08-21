local evt_PAGEL_FIRST = 100
local evt_PAGEL_REPT = 68
-- local evt_PAGEL_BREAK = 36

local evt_PAGER_FIRST = 101
local evt_PAGER_REPT = 69
-- local evt_PAGER_BREAK = 37

local evt_MDL_FIRST = 108
-- local evt_MDL__BREAK = 44
local evt_MDL_LONG = 140
-- local evt_MDL_REPT = 76

-- local evt_TELE_FIRST = 109
-- local evt_TELE_BREAK = 45
-- local evt_TELE_LONG = 141
-- local evt_TELE_REPT = 77

local evt_SYS_FIRST = 110
-- local evt_SYS_BREAK = 46
local evt_SYS_LONG = 142

-- local evt_ENTER_REPT = 66
local evt_EXIT_FIRST = 97

qs_ACC = {
	0,			-- on =
	.5,		-- forward =
	.5			-- brake =
}

qs_ABS = {
	0,			-- on = 
	0,			-- audio = 
	1,			-- type = 
	0,			-- dir = 
	-512,		-- trigger = 
	.5,		-- mul = 
	1,			-- full = 
	1,			-- reduce = 
	50,		-- pwmPercent = 
	2			-- pwmFreq = 
}

qs_ltActive = -1
qs_ltList = {}
qs_ltSwitch = 0
qs_ltTW = 300
qs_ltBest = 1000000
qs_ltLapTime = nil

qs_lang = 1
qs_skin = 5
qs_clock = 0
local kbSkin = 0

qs_LED = {255, 12.75, 0, 255, 155.55, 0, 0.21, 51}

qs_path = '/QSetup/'

local editMode = 1
local lcdCnt = 1

local groupNum = 1
local groups = {1}

local items = {
	{5, 1,
	 1, 1,
	 1, 1,
	 3, 1,
	15, 1,
	 3, 1}
,
	{7, 1,
	 9, 1,
	32, 1,
	64, 1,
	 6, 1,
	 8, 1,
	 3, 1,
	 1, 1}
,
	{4, 1,
	 5, 1,
	 6, 1,
	 8, 1,
	 1, 1,
	 2, 1}
,
	{1, 1,
	 3, 1}
,
	{1, 1,
	 6, 1}
}

local qs_sourceStr = 75		-- 75
qs_sourceThr = 76				-- 76

qs_sourceBat = 0
qs_sourceSB = 0
qs_sourceSC = 0

qs_4wsMode = 1
qs_4wsRev = 0
local channelStr = 0
qs_channelStB = -1
local channelThr = 1
local glVarsLast = 0

qs_rcCar = {}
qs_username = "your name"

qs_MinMax = {														--min and max Values for adjusting
	  20, -200,  10,  10, -100, -100,   0,   0, -100,  -- 9	--min Values
	 100,  200, 100, 100,  100,  100, 100, 100,  100}  --18	--max Values

qs_tmrDir = {0, 0, 0}

local floor = math.floor
local sub = string.sub

local function gsSiteNum(num)
	if not num then return items[groupNum][2] end
	items[groupNum][2] = num
end
local function getSites()
	return items[groupNum][1]
end
local function gsItemSel(num)
	if not num then return items[groupNum][items[groupNum][2] * 2 + 2] end
	items[groupNum][items[groupNum][2] * 2 + 2] = num
end
function qs_gsItems(num)
	if not num then return items[groupNum][items[groupNum][2] * 2 + 1] end
	items[groupNum][items[groupNum][2] * 2 + 1] = num
end
local function pushGroup(group)
	groups[1] = groups[1] + 1
	groups[groups[1]] = groupNum
	groupNum = group
end
function qs_popGroup()
	groupNum = groups[groups[1]]
	groups[1] = groups[1] - 1
end

function qs_playSignal(Frq, Dur)
	playTone(Frq, Dur, 0, PLAY_BACKGROUND + PLAY_NOW,0)
end

local popupCnt = 30
local popupText = {'Hello!', 'Welcome to', 'Quick Setup!'}
local popupX = 26
local popupY = 16
local popupInv = 10
function qs_setPopup(t, c, i)
	popupInv = i or 10
	popupText = {}
	popupCnt = 0
 	if not t then return end
	local w = 5
	for n = 1, #t do
		for v in string.gmatch(t[n], '([^|]+)') do
			popupText[#popupText + 1] = v
			if #v > w then w = #v end
		end
	end
	popupCnt = c or 15
	popupCnt = popupCnt * 2
	w = 61 - w * 2.95
	popupX = w >= 0 and w or 0
	w = 28 - #popupText * 4
	popupY = w >= 0 and w or 0
end

local adjCnt = 0
local adjSndCnt = 0
function qs_adjVal(value, vMin, vMax, step, event, freq)
	adjCnt = adjCnt - 1
	adjSndCnt = adjSndCnt - 1
	if adjCnt > 0 then return value end
	if event ~= EVT_ROT_LEFT and event ~= EVT_ROT_RIGHT then return value end
	if event == EVT_ROT_RIGHT then step = -step end
	if not freq and ((value == vMin and step < -5) or (value == vMax and step > 5)) then
		if adjSndCnt < 0 then playFile(step < 0 and 'SYSTEM/mintrim.wav' or 'SYSTEM/maxtrim.wav')
			adjSndCnt = 30 end
		playHaptic(20, 10)
		killEvents(event)
		adjCnt = 10
	end
	if vMin < 0 and vMax > 0 and not freq then
		if (value > 0 and (0 - step) >= value) or (value < 0 and (0 - step) <= value) then
			adjCnt = 10
			if adjSndCnt < 0 then playFile('SYSTEM/midtrim.wav')
				playHaptic(20, 10)
				adjSndCnt = 30 end
			return 0
		end
	end
	value = value + step
	if value < vMin then value = freq and vMax or vMin
	elseif value > vMax then value = freq and vMin or vMax
	end
	qs_playSignal(not freq and (value - vMin) / (vMax - vMin) * 400 + 600 or freq, 15)
	return value
end

local degre = math.pi / 180
local gfx, gfy = 0, 0
local gfrx, gfry = 10, 8
local gfscale = 1
local gfsin, gfcos = 1, 1

function qs_setAngel(angle)
	angle = angle * degre
	gfsin = math.sin(angle)
	gfcos = math.cos(angle)
end

local function rotatePoint(x, y)
	x = x - gfrx
	y = y - gfry
	return (x * gfcos - y * gfsin + gfrx) * gfscale + gfx, (x * gfsin + y * gfcos + gfry) * gfscale + gfy
end

local drawLine = lcd.drawLine
local drawText = lcd.drawText

function qs_line(x1, y1, x2, y2, pat, f)
	local pat = pat or SOLID
	local f = f or FORCE
	x1, y1 = rotatePoint(x1, y1)
	x2, y2 = rotatePoint(x2, y2)
	drawLine(x1, y1, x2, y2, pat, f)
end

--local function gfLines(pat, f, ...)
--	local p = {...}
--	for n = 1, #p - 3, 2 do qs_line(p[n], p[n+1], p[n+2], p[n+3], pat, f) end
--	p = {}
--end

local function gfFTriangle(x1, y1, x2, y2, x3, y3, pat, f)
	local pat = pat or SOLID
	local f = f or FORCE
	if y1 > y3 then x1, y1, x3, y3 = x3, y3, x1, y1 end
	if y1 > y2 then x1, y1, x2, y2 = x2, y2, x1, y1 end
	if y2 > y3 then x2, y2, x3, y3 = x3, y3, x2, y2 end
	local xa, addxa = x1, (x3 - x1) / (y3-y1 < 1 and 1 or y3-y1)
	local xb, addxb = x1, (x2 - x1) / (y2-y1 < 1 and 1 or y2-y1)
	local y2u = floor(y2)
	for y = floor(y1), floor(y3 - 1) do
		if y == y2u then addxb = (x3 - x2) / (y3-y2 < 1 and 1 or y3-y2) xb = x2  end
		drawLine(xa, y, xb, y, pat, f)
		xa, xb = xa + addxa, xb + addxb
	end
end

function qs_gfRec(x1, y1, x2, y2, fill, pat, f)
	local pat = pat or SOLID
	local f = f or FORCE
	local x3 = x1
	local y3 = y2
	local x4 = x2
	local y4 = y1
	x1, y1 = rotatePoint(x1, y1)
	x2, y2 = rotatePoint(x2, y2)
	x3, y3 = rotatePoint(x3, y3)
	x4, y4 = rotatePoint(x4, y4)
	if fill == 1 then gfFTriangle(x1, y1, x2, y2, x3, y3, pat, f)
	                  gfFTriangle(x1, y1, x2, y2, x4, y4, pat, f) end
	drawLine(x1, y1, x4, y4, pat, f)
	drawLine(x3, y3, x2, y2, pat, f)
	drawLine(x1, y1, x3, y3, pat, f)
	drawLine(x4, y4, x2, y2, pat, f)
end

function qs_setAll(x, y, rx, ry, angle, scale, setAng)
	gfscale = scale or 1
	gfx, gfy = x, y
	gfrx, gfry = rx, ry
	if setAng == 1 then qs_setAngel(angle or 0) end
end

function qs_drawTitel(text, font)
	local y = 0
	if font == MIDSIZE and #text > 16 then font, y = 0, 2 end
	if font == 0 and #text > 21 then font, y = SMLSIZE, 3 end
	lcd.drawFilledRectangle(0, 0, 128, 12, 0)
	drawText(64, y, text, font + CENTER + INVERS)
end

qs_listFirst = {}
local blinkList = 0
function qs_drawList(titel, sel, t, event, rows, y, dist, font, p, u, minmax, eMode, disp, c)
	if not sel then return end
	if titel then qs_drawTitel(titel, MIDSIZE) end
	local gs = groupNum * 1000 + gsSiteNum() * 10
	if not qs_listFirst[gs] then qs_listFirst[gs] = 1 end
	local pl, lf = {}, qs_listFirst[gs]
	if not disp then
		for n = 1, #t do pl[n] = n end
	else
		for n = 1, #disp do if sub(disp, n, n) == '+' then pl[#pl + 1] = n end end
	end
	local rows = rows or 6
	rows = rows - 1
	local y = y or 14
	local dist = dist or 8
	blinkList = blinkList > 0 and blinkList - 1 or 20
	if not p then sel = qs_adjVal(sel, 1, #t, -floor((getRotEncSpeed() + 2) / 3), event, 800) end
	if sel < lf then lf = sel
	elseif sel - rows > lf then lf = sel - rows
	end
	qs_listFirst[gs] = lf
	local last = lf + rows
	if last > #pl then last = #pl end
	for n = lf, last do
		local txt = t[pl[n]] == '' and ' ' or t[pl[n]]
		if not p then
			drawText(font or 64, y, txt, (#txt < 22 and 0 or SMLSIZE) + CENTER + (n == sel and INVERS or 0))
		else
			local val, convert = p[pl[n]], 1
			if c and c[pl[n]] then convert = c[pl[n]] end
			val = val / convert
			drawText(font == MIDSIZE and 95 or 99, y, txt..':', RIGHT)
			local unit = not u and ' ' or sub(u, pl[n], pl[n])
			if unit == '|' then
				if sel == n then
					lcd.drawRectangle(112, y - 1, 14, 9, FORCE)
					if eMode == 2 then
						val = val == 0 and 1 or 0 
						qs_playSignal(val == 0 and 800 or 1200, 30) eMode = 3
					end
				end
				lcd.drawRectangle(113, y, 12, 7, FORCE)
				lcd.drawFilledRectangle(val == 0 and 115 or 119, y + 2, 4, 3, FORCE)
			else
				if eMode == 2 and sel == n then
					val = qs_adjVal(val, minmax[pl[n]], minmax[pl[n] + #minmax / 2], getRotEncSpeed(), event)
					if event == EVT_ROT_LEFT or event == EVT_ROT_RIGHT then blinkList = 20 end
				end
				local rx, ry, rw, rh = 103, y - 1, 25, 9
				if unit == '-' then
					local x = (val - minmax[pl[n]]) * 20 / (minmax[pl[n] + #minmax / 2] - minmax[pl[n]]) + 104
					lcd.drawFilledRectangle(103, y + 3, 25, 1, FORCE)
					lcd.drawFilledRectangle(x > 125 and 125 or x, y, 3, 7, FORCE)
				else
					rx, ry, rw, rh = 1, y - 1, 0, 9
					if font == MIDSIZE then rx, ry, rw, rh = 3, y - 4, 4, 12 end
					drawText(128, y, unit, RIGHT)
					lcd.drawNumber(120, y - rw, val, RIGHT + font)
					rx = lcd.getLastLeftPos() - rx
					rw = 128 - rx
				end
				if sel == n then
					if eMode == 1 or (eMode == 2 and blinkList > 8) then lcd.drawFilledRectangle(rx, ry, rw, rh) end
				end
			end
			p[pl[n]] = val * convert
		end
		y = y + dist
	end
	if not p then return sel else return eMode end
end

function qs_getModelName()
	local name = qs_rcCar.name
	if name == '' then
		local num = tonumber(string.sub(qs_rcCar.filename, 6, 7)) + 1
		name = 'MODEL'..(num < 10 and '0' or '')..num
	end
	return name
end

function qs_writeConf()
	local f = io.open(qs_path .. 'save/' .. qs_getModelName() .. '.cfg', 'w')
	local s = ', '
	io.write(f, qs_username, s, qs_lang, s, qs_skin, s, qs_clock, s, kbSkin)
	for n = 1, 10 do io.write(f, s, qs_ABS[n]) end
	for n = 1, 3 do io.write(f, s, qs_ACC[n]) end
	for n = 1, 8 do io.write(f, s, qs_LED[n]) end
	io.write(f, s, qs_4wsRev)
	io.close(f)
end

-- function qs_readData(fn, d, toNum)
	-- local i = fstat(fn)
	-- if i == nil then return false end
	-- local f = io.open(fn, 'r')
	-- local c = io.read(f, i.size)
	-- io.close(f)
	-- for v in string.gmatch(c, '([^,]+)') do
		-- d[#d + 1] = toNum == 1 and tonumber(v) or v
	-- end
	-- c = nil
	-- collectgarbage('collect')
	-- return true
-- end

function qs_readData(fn, d, toNum)
	local f = io.open(fn, 'r')
	if f == nil then return false end
	local word = ''
	repeat
		local chr = io.read(f, 1)
		if chr ~= ',' and chr ~= '' then word = word .. chr
		elseif word ~= '' then d[#d + 1] = toNum == 1 and tonumber(word) or word
			word = '' end
	until chr == ''
	io.close(f)
	return true
end

local function readConf()
	local d = {}
	if qs_readData(qs_path .. 'save/' .. qs_getModelName() .. '.cfg', d) then
		for n = 2, #d do d[n] = tonumber(d[n]) or 0 end
		local a = d[1] or 'your name'
		if #a > 13 then a = sub(a, 1, 13) end qs_username = a
		a = d[2] or 1 if a < 1 or a > 2 then a = 1 end qs_lang = a
		a = d[3] if a < 0 or a > 31 then a = 5 end qs_skin = a
		a = d[4] if a < 0 or a > 1 then a = 0 end qs_clock = a
		a = d[5] if a < 0 or a > 3 then a = 0 end kbSkin = a
		if #d < 26 then qs_writeConf() return end
		for n = 1, 10 do qs_ABS[n] = d[n + 5] end
		for n = 1, 3 do qs_ACC[n] = d[n + 15] end
		for n = 1, 8 do qs_LED[n] = d[n + 18] end
		if #d < 27 then qs_writeConf() return end
		qs_4wsRev = d[27]
	else
		qs_writeConf()
	end
end

local inputChars = {'1234567890 qwertzuiop+asdfghjkl[]<yxcvbnm,.-',
						 '!"?\\%&/()= QWERTZUIOP*ASDFGHJKL|^>YXCVBNM;:_'}
local kbCsr = 1
local uppCase = 1
local InputCsr = 0
local blkCsr = 0
function qs_inputText(inputText, maxChars, editMode, event, fbdChars)
	if not inputText then kbCsr, uppCase, InputCsr = 17, 1, -1	-- Initialization of the initial parameters
		return '' end
	inputText = inputText..' '	-- Add space to it
	if InputCsr == -1 then InputCsr = #inputText end	-- Input cursor to the set position or start position
	blkCsr = blkCsr > 0 and blkCsr - 1 or 15	-- Flashing frequency of the cursor
	if event == evt_SYS_LONG then inputText = '' InputCsr = 1 end
	if (event == evt_PAGEL_FIRST or event == evt_PAGEL_REPT) and InputCsr > 1 then
		InputCsr = InputCsr - 1
		blkCsr = 15
	end
	if (event == evt_PAGER_FIRST or event == evt_PAGER_REPT) and InputCsr < #inputText then
		InputCsr = InputCsr + 1
		blkCsr = 15
	end
	if editMode == 3 and #inputText <= maxChars then
		local chr = sub(inputChars[uppCase], kbCsr, kbCsr)
		for n = 1, #fbdChars do if chr == sub(fbdChars, n, n) then chr = '' end end
		if chr ~= '' then		-- :/*<>
			inputText = sub(inputText, 1, InputCsr - 1)..chr..sub(inputText, InputCsr, #inputText)
			InputCsr = InputCsr + 1 blkCsr = 15 
		end
	end
	if event == evt_SYS_FIRST and #inputText > 0 and InputCsr > 1 then
		inputText = sub(inputText, 1, InputCsr - 2)..sub(inputText, InputCsr, #inputText)
		InputCsr = InputCsr - 1 blkCsr = 15 
	end
	if event == evt_MDL_FIRST then uppCase = uppCase == 1 and 2 or 1 end
	if event == evt_MDL_LONG then
		kbSkin = kbSkin < 3 and kbSkin + 1 or 0
		uppCase = uppCase == 1 and 2 or 1
		qs_writeConf()
	end
	kbCsr = qs_adjVal(kbCsr, 1, #inputChars[uppCase], -(math.floor((getRotEncSpeed() + 3) / 4)), event, 800)
	local x, y, xp = 0, 0, 5
	for n = 1, #inputChars[uppCase] do
		if n < 12 then y, x = 26, n * 10 - 7 + xp
		elseif n < 23 then y, x = 36, (n - 11) * 10 - 3 + xp
		elseif n < 34 then y, x = 46, (n - 22) * 10 + 1 + xp
		else y, x = 56, (n - 33) * 10 - 5 + xp
		end
		if n == 11 then
			lcd.drawFilledRectangle(x - 1, y + 5, 7, 2, 0)
			lcd.drawFilledRectangle(x, y + 5, 5, 1, 0)
		else
			local lc = sub(inputChars[uppCase], n, n)
			drawText(x, y, lc, 0)
			local lx = lcd.getLastPos()
			if lx < x + 4 then drawText(x, y, ' ', 0)  -- lcd.drawFilledRectangle(x, y, 8, 7, ERASE)
				drawText(x + (lx - x) / 2 + 1, y, lc, 0) end
		end
		if kbSkin % 2 >= 1 then lcd.drawFilledRectangle(x - 2, y - 1, 9, 9, 0) end
		if kbCsr == n then lcd.drawFilledRectangle(x - 2, y - 1, 9, 9, 0) end
	end
	y = 12
	drawText(0, y, inputText, MIDSIZE)
	x = 68 - (lcd.getLastPos()) / 2
	if x < 2 then
		drawText(0, y, inputText, 0) 
		x, y = 67 - lcd.getLastPos() / 2, 15
	end
	lcd.drawFilledRectangle(0, 12, 128, 13, ERASE)
	for n = 1, #inputText do
		drawText(x, y, sub(inputText, n, n), (y == 12 and MIDSIZE or 0)) -- + (n == InputCsr and (INVERS + BLINK) or 0))
		if n == InputCsr and blkCsr > 6 then lcd.drawFilledRectangle(x - 1, y == 12 and y + 1 or y, 1, y == 12 and 11 or 8, FORCE) end
		x = lcd.getLastPos() + (y == 12 and -1 or 0)
	end
	if kbSkin % 4 >= 2 then lcd.drawFilledRectangle(0, 12, 128, 52, 0) end
	return sub(inputText, 1, #inputText - 1)
end

--Main
------------------------------------------------------------------------------------------------------------
local pages = {'QS1', 'QS2', 'QS345', 'QS345', 'QS345'}
local scriptDir = qs_path..'scripts/'
local pageRun = ''
local runScript
local function qs_run(event)
	if editMode == 2 then lcd.resetBacklightTimeout() lcdCnt = 0 end
	if event == 0 then
		if lcdCnt > 1 then lcdCnt = lcdCnt - 1
			local glVars = 0
			for i = 0, 3 do glVars = glVars + model.getGlobalVariable(i, 0) end
			if glVars ~= glVarsLast then lcdCnt = 1
				glVarsLast = glVars
			end
			return 1
		else lcdCnt = 72000 end
	end
	if event == EVT_ENTER_FIRST then editMode = editMode + 1
	elseif event == evt_EXIT_FIRST then
		if editMode == 2 then editMode = 4
		elseif editMode == 1 then
			if groups[1] == 1 then return 2
			else qs_popGroup()
			end
		end
	elseif editMode == 1 then
		local i, sn, sites = qs_gsItems(), gsSiteNum(), getSites()
		if event == EVT_ROT_LEFT or event == EVT_ROT_RIGHT then
			if i > 1 then gsItemSel(qs_adjVal(gsItemSel(), 1, i, -(floor((getRotEncSpeed() + 2) / 3)), event, 800)) end
		elseif event == evt_PAGER_FIRST then
			gsSiteNum(sn < sites and sn + 1 or 1)
		elseif event == evt_PAGEL_FIRST then
			gsSiteNum(sn > 1 and sn - 1 or sites)
		end
	end

	local pageLoad = pages[groupNum]
	if pageLoad ~= pageRun then
		runScript = {}
		collectgarbage("collect")
		local fn = scriptDir..pageLoad  -- to setup your rc car
		runScript = loadScript(fn)  -- to setup your rc car
		pageRun = pageLoad
		runScript = runScript()
		collectgarbage("collect")
		if fstat(fn..'.lua') then del(fn..'.lua') end
	end
	lcd.clear()
	local iSel, grp = gsItemSel(), groupNum
	editMode, lcdCnt, iSel, grp = runScript(groupNum, event, gsSiteNum(), iSel, qs_lang, editMode, lcdCnt,
	channelStr, channelThr, getSourceValue(qs_sourceStr), getSourceValue(qs_sourceThr))
	gsItemSel(iSel)
	if grp ~= groupNum then pushGroup(grp) lcdCnt = 1 editMode = 1 end

	-- local s = getSites()  -- Site indicator for menue navigation on the upper edge
	-- for n = 0, s do lcd.drawPoint(64 - s * 3 + n * 6, 0, 0) end
	-- local x = 63 - s * 3 + gsSiteNum() * 6
	-- drawLine(x - 5, 0, x, 0, SOLID, 0)

	if popupCnt > 0 then
		popupCnt = popupCnt - 1
		if event == EVT_ROT_LEFT or event == EVT_ROT_RIGHT then popupCnt = 0 end
		local w = 128 - popupX - popupX
		local h = 63 - popupY - popupY
		lcd.drawFilledRectangle(popupX, popupY, w, h, ERASE)
		lcd.drawRectangle(popupX + 1, popupY + 1, w - 2, h - 2, FORCE)
		lcd.drawFilledRectangle(popupX + 2, popupY + 2, w - 4, 8, FORCE)
		for n = 1, #popupText do
			drawText(64, n * 8 + popupY - (n == 1 and 6 or 4), popupText[n], CENTER + (n == 1 and INVERS or n == popupInv and INVERS or 0))
		end
		lcdCnt = 0
	end

	if qs_skin % 32 >= 16 then lcd.drawFilledRectangle(0, 0, 128, 64, 0) end  -- reverse screen if activated

	if editMode > 2 and editMode < 5 then editMode = 1
		lcdCnt = 0 end

	return 0
end

function qs_init(ri)
	if not ri then						-- initializes the following once
		qs_rcCar = model.getInfo()
		qs_sourceBat = getFieldInfo('tx-voltage').id	-- 241
		qs_sourceSB = getFieldInfo('sb').id				-- 101
		qs_sourceSC = getFieldInfo('sc').id				-- 102
		qs_ltSwitch = 1
		readConf()

		local fn = '/SCRIPTS/TELEMETRY/QSetup.lua' if fstat(fn) then del(fn) end

		local trims = {94, 93, 92, 95}
		for n = 3, 6 do
			local csf = model.getCustomFunction(n)
			if csf.value == 0 then
				csf.value = trims[n - 2]
				model.setCustomFunction(n, csf)
			end
		end

		local csf = model.getCustomFunction(2)
		csf.name = 'QSLED'
		model.setCustomFunction(2, csf)
	end
	if qs_rcCar.extendedLimits then qs_MinMax[16] = 150 qs_MinMax[17] = 150 end
	local aux = 1
	for n = 0, 5 do
		local buffer = model.getOutput(n)
		if buffer.name == 'Str' then channelStr = n

		elseif buffer.name == 'StB' then
			qs_channelStB = n
			local StF, StB = true, false
			if qs_4wsMode >= 2 then StB = true end
			if qs_4wsMode == 3 then StF = false end
			setStickySwitch(6, StF)
			setStickySwitch(7, StB)
			if qs_4wsMode == 4 then buffer.revert = 1 - qs_4wsRev
			else buffer.revert = qs_4wsRev
			end
			model.setOutput(n, buffer)

		elseif buffer.name == 'Thr' then
			channelThr = n
			local offset = model.getGlobalVariable(6, 0) / 10
			local csf = model.getCustomFunction(0)
			csf.param = n
			csf.value = buffer.revert == 0 and offset or -offset
			model.setCustomFunction(0, csf)
		elseif buffer.name == '' then
			buffer.name = 'AUX'..aux
			model.setOutput(n, buffer)
			aux = aux + 1
		end
	end
end

return { init = qs_init, run = qs_run }
