local absPWM = 100
local absFreq = 2
local absActive = 0

local brakeState = 1
local brakeRate = model.getGlobalVariable(3, 0)
local brakeCnt = 0

local thrTrim = model.getGlobalVariable(6, 0)
local fwdRate = model.getGlobalVariable(2, 0)
local accActive = 0

local ltRun = 0
local ltLastSwitch = 0
local ltDiff = 0
local speakCnt = 0

if fstat('/SCRIPTS/FUNCTIONS/QSBG.lua') then del('/SCRIPTS/FUNCTIONS/QSBG.lua') end

local function qs_run()
	if not qs_sourceThr then return end
	local srcThrVal = getSourceValue(qs_sourceThr)

	if qs_ltActive == 1 then			-- Laptime active?
		local Time = getTime()
		if speakCnt > 0 then speakCnt = speakCnt - 1 end
		local switch = getSourceValue(qs_ltSwitch == 0 and qs_sourceSB or qs_sourceSC) < 0 and 0 or 1
		ltNum = #qs_ltList + 1
		if ltNum <= 1000 then
			if ltRun == 0 then				-- waiting to start
				if srcThrVal >= 950 then
					ltRun = 1
					if ltNum == 1 then
						qs_ltList[ltNum] = Time
						ltDiff = 0
						qs_ltBest = 1000000
					else
						ltDiff = Time - qs_ltList[ltNum - 1]
					end
					playFile('start.wav')
				end
			elseif ltRun == 1 then
				local t = Time - ltDiff
				local t2 = t - qs_ltList[ltNum - 1]
				qs_ltLapTime = t2
				if ltLastSwitch == 0 and switch == 1 then
					if t2 >= qs_ltTW then
						qs_ltList[ltNum] = t
						if t2 < qs_ltBest then qs_ltBest = t2 end
						qs_playSignal(1000, 50)
						local m = math.floor(t2 / 6000)
						t2 = t2 - m * 6000
						if speakCnt == 0 then
							speakCnt = 79
							if m > 0 then playNumber(m, 36) end
							playNumber(t2, 37, PREC2)
							playFile('lap.wav')
							playNumber(ltNum - 1, 0)
						end
					end
				end
			end
		else
			qs_ltActive = 0
		end
		ltLastSwitch = switch
	else
		ltRun = 0
		qs_ltLapTime = nil
	end

	local r, g, b = 0, 0, 0
	if qs_ACC[1] == 1 then
		if srcThrVal >= 20 then
			accActive = 1
			model.setGlobalVariable(6, 0, fwdRate * qs_ACC[2] + thrTrim)
			r, g, b = 255, 0, 255
		elseif srcThrVal <= -20 then
			accActive = 1
			model.setGlobalVariable(6, 0, thrTrim - brakeRate * qs_ACC[3])
			r, g, b = 255, 0, 0
		else
			if accActive == 1 then
				model.setGlobalVariable(6, 0, thrTrim)
				accActive = 0
			end
			fwdRate = model.getGlobalVariable(2, 0)
			thrTrim = model.getGlobalVariable(6, 0)
		end
	else
		if accActive == 1 then
			model.setGlobalVariable(6, 0, thrTrim)
			accActive = 0
		end
		fwdRate = model.getGlobalVariable(2, 0)
		thrTrim = model.getGlobalVariable(6, 0)
	end

	if qs_ABS[1] == 1 then
		if srcThrVal <= qs_ABS[5] then
			absActive = 1
			if qs_ABS[3] == 1 then
				if absFreq > 1 then
					absFreq = absFreq - 1
					brakeCnt = 2
				else
					absFreq = qs_ABS[10]
					local subtr = qs_ABS[4] == 1 and 100 - qs_ABS[9] or qs_ABS[9]
					absPWM = absPWM - subtr
					brakeState = absPWM > 0 and 1 or 0
					if absPWM < 1 then absPWM = absPWM + 100 end
					if qs_ABS[4] == 1 then brakeState = brakeState == 0 and 1 or 0 end
					brakeCnt = 1
				end
			end
			if brakeCnt > 1 then
				brakeCnt = brakeCnt - 1
			else
				if brakeState == 1 then
					model.setGlobalVariable(3, 0, brakeRate)
					brakeCnt = qs_ABS[7]
					brakeState = 0
				else
					model.setGlobalVariable(3, 0, brakeRate * qs_ABS[6])
					brakeCnt = qs_ABS[8]
					brakeState = 1
				end
			end
			if brakeState == 0 then r, g, b = 0, 255, 255
				if qs_ABS[2] == 1 then qs_playSignal(161, 20) end
			end
		else
			if absActive == 1 then
				model.setGlobalVariable(3, 0, brakeRate)
				absActive = 0
			end
			brakeRate = model.getGlobalVariable(3, 0)
			absPWM, absFreq = 100, 1
			brakeState = qs_ABS[4] == 0 and 1 or 0
			brakeCnt = 1
		end
	else
		if absActive == 1 then
			model.setGlobalVariable(3, 0, brakeRate)
			absActive = 0
		end
		brakeRate = model.getGlobalVariable(3, 0)
	end
	if srcThrVal < 0 then srcThrVal = -srcThrVal end
	srcThrVal = srcThrVal / 1024
	setRGBLedColor(0, r * srcThrVal, g * srcThrVal, b * srcThrVal)
end

local function background()
end

local function init()
	if thrTrim < -20 or thrTrim > 20 then
		thrTrim = 0
		model.setGlobalVariable(6, 0, thrTrim)
	end
end

return { run = qs_run, init = init, background = background}
