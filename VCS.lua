-------------------------------------------------------------------------
-- By Mick 2017 - a mixture of the Kiss Telemetry script by DynamikArray
-- https://github.com/DynamikArray/KISS_Battery_Monitor
-------------------------------------------------------------------------

local versionInfo = "Virtual Current Sensor - v0.1"

local lastAlert = 0

local endTime = 80

local blnMenuMode = 0

local alertPerc = 10

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
	playNumber(percVal,percentUnit)
	lastAlert = percVal  -- Set lastAlert
end

-- critical alert and Logging of last Value Played
local function playCritical(percVal)
	playFile("batcrit.wav")
	lastAlert = percVal  -- Set lastAlert
end

function getTelemetryId(name)
	field = getFieldInfo(name)

	if getFieldInfo(name) then
		return field.id
	end

	return -1
end


----------------------------------------------------------------
--
----------------------------------------------------------------
local function playAlerts()

    percVal = 0
    curTime = getValue('timer1')

   -- if curTime ~= 0 then
		percVal =  round(((curTime/endTime) * 100),0)

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
   -- end

end

----------------------------------------------------------------
--
----------------------------------------------------------------

local function drawAlerts()

	percVal = 0

	--RSSI = getValue(getTelemetryId("RSSI"))

	--if RSSI == 0 then
	--	model.resetTimer(0)
	--end

     curTime = getValue('timer1')

	percVal =  round(((curTime/endTime) * 100),0)
	lcd.drawText(5, 10, "USED: "..curTime.." s" , MIDSIZE)
	lcd.drawText(90, 30, percVal.." %" , MIDSIZE)

end


local function doAlert()
  playAlerts()
  drawAlerts()
end

local function draw()
  drawAlerts()
end


----------------------------------------------------------------
--
----------------------------------------------------------------
local function init_func()
  doAlert()
end
--------------------------------


----------------------------------------------------------------
--
----------------------------------------------------------------
local function bg_func()
  playAlerts()
end
--------------------------------


----------------------------------------------------------------
--
----------------------------------------------------------------
local function run_func(event)

	if blnMenuMode == 1 then

		if event == 32 then
			--Take us out of menu mode
			blnMenuMode = 0
		end

		-- Respond to user KeyPresses for Setup
		if event == EVT_PLUS_FIRST then
			alertPerc = alertPerc + 1
		end

		-- Long Presses
		if event == 68 then
			alertPerc = alertPerc + 1
		end

		if event == EVT_MINUS_FIRST then
			alertPerc = alertPerc - 1
		end

		-- Long Presses
		if event == 69 then
			alertPerc = alertPerc - 1
		end

		lcd.clear()

		lcd.drawScreenTitle(versionInfo,2,2)
		lcd.drawText(30,10, "Set Percentage Notification")
		lcd.drawText(70,20,"Every "..alertPerc.." %",MIDSIZE)
		lcd.drawText(66, 35, "Use +/- to change",SMLSIZE)

		lcd.drawText(53, 55, "Press [MENU] to return",SMLSIZE)

	else

		if event == 32 then
			--Put us in menu mode
			blnMenuMode = 1
		end

		-- Respond to user KeyPresses for Setup
		if event == EVT_PLUS_FIRST then
			endTime = endTime + 1
		end

		if event == 68 then
			endTime = endTime + 1
		end

		if event == EVT_MINUS_FIRST then
			endTime = endTime - 1
			if endTime < 1 then
				endTime = 1
			end
		end

		if event == 69 then
			endTime = endTime - 1
			if endTime < 1 then
				endTime = 1
			end
		end


		--Update our screen
		lcd.clear()

		lcd.drawScreenTitle(versionInfo,1,2)

		lcd.drawGauge(6, 25, 70, 20, getValue('timer1') , endTime)
		lcd.drawText(130, 10, "End time: ",MIDSIZE)
		lcd.drawText(160, 25, endTime,MIDSIZE)
		lcd.drawText(130, 40, "Use +/- to change",SMLSIZE)

		lcd.drawText(35, 55, "Press [MENU] for more options",SMLSIZE)

		draw()
		doAlert()
	end
end
--------------------------------

return {run=run_func, background=bg_func, init=init_func  }
