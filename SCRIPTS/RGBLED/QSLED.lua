local ledCycle = {
	0.25,
	0.5,
	0.75,
	1,
	1,
	1,
	0.75,
	0.5,
	0.25,
	0,
	0,
	0
}
local degre = math.pi / 180
local ledPoint = 1
local sndPlay = false
local flash = 0

local function run()
	if not sndPlay then
		playFile('/SOUNDS/police.wav')
		sndPlay = true
	end

	local p1 = ledPoint <= 2 and ledPoint + 10 or ledPoint - 2
	local p2 = ledPoint
	for i = 1, 2 do
		local pw = ledCycle[p1]
		local pn = ledCycle[p2]
		setRGBLedColor(i, 255 * pw, 255 * pw, 255 * pw)
		setRGBLedColor(i + 2, 255 * (1 - pn), 0, 0)
		setRGBLedColor(i + 4, 0, 55 * pn, 255 * pn)
		p2 = p2 <= 3 and p2 + 9 or p2 - 3
	end
	ledPoint = ledPoint < 12 and ledPoint + 1 or 1
end

local function background()
	sndPlay = false
	local br = 0
	if qs_LED[7] > 0 then
		br = flash * degre
		br = 1 - math.sin(br)
		br = qs_LED[7] * br
	end
	br = 1 - qs_LED[7] + br
	local r1, g1, b1 = qs_LED[1] * br, qs_LED[2] * br, qs_LED[3] * br
	local r2, g2, b2 = qs_LED[4] * br, qs_LED[5] * br, qs_LED[6] * br
	for i = 1, 5, 2 do
		setRGBLedColor(i, r1, g1, b1)
		setRGBLedColor(i + 1, r2, g2, b2)
	end
	flash = flash + qs_LED[8]
	if flash > 180 then flash = flash - 180 end
end

local function init()
	local fn = '/SCRIPTS/RGBLED/QSLED.lua' if fstat(fn) then del(fn) end
end

return { run=run, background=background, init=init }
