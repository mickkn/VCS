-------------------------------------------------------------------------
-- By Mick 29-12-2016
-- A virtual current sensor based on a throttle% timer in the OpenTX software
-- All credit goes to DynamikArray
-- https://github.com/DynamikArray/KISS_Battery_Monitor
-------------------------------------------------------------------------

local versionInfo = "Virtual Current Sensor - v0.2"

local lastAlert = 0
local blnMenuMode = 0         -- Start menu in screen one

local endTime = 80            -- Change if you want a different start end time
local alertPerc = 10          -- Change if you want a different start percentage
local TIMER = 'timer1'        -- Change if you want a different timer

-- OpenTX 2.0 - Percent Unit = 8 // OpenTx 2.1 - Percent Unit = 13
-- see: https://opentx.gitbooks.io/opentx-lua-reference-guide/content/general/playNumber.html
local percentUnit = 13

----------------------------------------------------------------
-- Custom Functions & Utilities
----------------------------------------------------------------
-- Rounding Function
local function round(val, decimal)
     local exp = decimal and 10^decimal or 1
     return math.ceil(val * exp - 0.5) / exp
end

-- Alert and Logging of last Value Played
local function playPerc(percVal)
     playNumber(percVal, percentUnit)
     lastAlert = percVal -- Set lastAlert
end

-- Critical alert and Logging of last Value Played
local function playCritical(percVal)
     playFile("batcrit.wav")
     lastAlert = percVal -- Set lastAlert
end

----------------------------------------------------------------
-- Playing alerts according to chosen percentage warning
----------------------------------------------------------------
local function playAlerts()

     --percVal = 0 -- Percentage value
     curTime = getValue(TIMER) -- Get current time in seconds

	percVal =  round(((curTime/endTime) * 100),0) -- Percentage from current time

     if percVal ~= lastAlert then
	     -- Alert the user we are in critical alert
		if percVal > 100 then
               playCritical(percVal)
		elseif percVal > 90 and percVal < 100 then
		     playPerc(percVal)
		elseif percVal % alertPerc == 0 then
		     playPerc(percVal)
          end
     end
     
end

----------------------------------------------------------------
-- Update the percentage bar and time on screen
----------------------------------------------------------------

local function drawAlerts()

     curTime = getValue(TIMER)

	percVal =  round(((curTime/endTime) * 100),0)
	lcd.drawText(5, 10, "USED: "..curTime.." s" , MIDSIZE)
     lcd.drawText(90, 30, percVal.." %" , MIDSIZE)

end

----------------------------------------------------------------
-- Initial function
----------------------------------------------------------------
local function init_func()
     playAlerts()
     drawAlerts()
end
--------------------------------

----------------------------------------------------------------
-- Background function
----------------------------------------------------------------
local function bg_func()
     playAlerts()
end
--------------------------------


----------------------------------------------------------------
-- Run function
----------------------------------------------------------------
local function run_func(event)

	if blnMenuMode == 1 then

		if event == 32 then
			--Take us out of menu mode
			blnMenuMode = 0
		end

		-- Respond to user KeyPresses for Setup
		if (event == EVT_PLUS_FIRST) or (event == 68) then
			alertPerc = alertPerc + 1
			if alertPerc >= 100 then
			     alertPerc = 100
			end
		end

		if (event == EVT_MINUS_FIRST) or (event == 69) then
			alertPerc = alertPerc - 1
			if alertPerc <= 0 then
			     alertPerc = 0
			end
		end

		lcd.clear()

		lcd.drawScreenTitle(versionInfo,2,2)
		lcd.drawText(30, 10, "Set Percentage Notification")
		lcd.drawText(70, 20, "Every "..alertPerc.." %",MIDSIZE)
		lcd.drawText(66, 35, "Use +/- to change",SMLSIZE)

		lcd.drawText(53, 55, "Press [MENU] to return",SMLSIZE)

	else

		if event == 32 then
			--Put us in menu mode
			blnMenuMode = 1
		end

		-- Respond to user KeyPresses for Setup
		if (event == EVT_PLUS_FIRST) or (event == 68) then
			endTime = endTime + 1
			if endTime >= 9999 then
				endTime = 9999
			end
		end

		if (event == EVT_MINUS_FIRST) or (event == 69) then
			endTime = endTime - 1
			if endTime <= 1 then
				endTime = 1
			end
		end


		--Update screen
		lcd.clear()

		lcd.drawScreenTitle(versionInfo,1,2)

		lcd.drawGauge(6, 25, 70, 20, getValue('timer1') , endTime)
		lcd.drawText(133, 10, "End Time : ",MIDSIZE)
		lcd.drawText(160, 25, endTime,MIDSIZE)
		lcd.drawText(130, 40, "Use +/- to change",SMLSIZE)

		lcd.drawText(36, 55, "Press [MENU] for more options",SMLSIZE)

		playAlerts()
          drawAlerts()
	end
end
--------------------------------

return {run=run_func, background=bg_func, init=init_func  }
