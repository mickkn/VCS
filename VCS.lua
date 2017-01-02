-------------------------------------------------------------------------
-- By Mick 29-12-2016
-- A virtual current sensor based on a throttle% timer in the OpenTX software
-- All credit goes to DynamikArray
-- https://github.com/DynamikArray/KISS_Battery_Monitor
-------------------------------------------------------------------------

local versionInfo = "Virtual Current Sensor - v0.3"

local lastAlert = 0
local blnMenuMode = 0         -- Start menu in screen one

local endTime = 0             -- Change if you want a different start end time
local alertPerc = 10          -- Change if you want a different start percentage
local TIMER = 'timer1'        -- Change if you want a different timer

local maxDraw = 0             -- Initialize max draw variable
local battCap = 0             -- Initialize battery capacity

local menuChoice = 0          -- Initialize menu choice in flight time calculator
local menuChoosen = 0         -- Initialize menu chosen in flight time calculator

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

     maxDraw = model.getGlobalVariable(0, 0)  -- Get last maximum current draw in Amps
     battCap = model.getGlobalVariable(1, 0)*10  -- Get last battery capacity in mAh
     endTime = round((battCap/(maxDraw*1000))*60*60,0) -- Calculate end time
     -----------------------------------------------------------
     -- Initial values to some defaults if values is 0
     -----------------------------------------------------------
     if (maxDraw == 0) then
          maxDraw = 67
          battCap = 1300
          endTime = round((battCap/(maxDraw*1000))*60*60,0)
     end

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

     ---------------------------------
     -- Flight time calculator
     ---------------------------------
     if blnMenuMode == 2 then 

          if (event == 32) then -- Back to start screen
			blnMenuMode = 0
			-- Reset menu
			menuChoice = 0
			menuChoosen = 0
		end

          -- Calculate end time
          endTimeCalc = round((battCap/(maxDraw*1000))*60*60,0) -- in seconds

          ----------------------------------------
		-- Respond to user key presses
		----------------------------------------
		if (menuChoosen == 0) then -- No options is selected with ENTER
		     if (event == EVT_MINUS_FIRST) or (event == 69) then
                    menuChoice = menuChoice + 1
                    if (menuChoice > 2) then
                         menuChoice = 0
                    end
		     end
		     
		     if (event == EVT_PLUS_FIRST) or (event == 68) then
                    menuChoice = menuChoice - 1
                    if (menuChoice < 0) then
                         menuChoice = 2
                    end
		     end 
		else -- A option is selected with ENTER
		     if (event == EVT_PLUS_FIRST) or (event == 68) then
		          if (menuChoice == 1) then
		               battCap = (battCap + 10)
		               if (battCap > 6000) then
		                    battCap = 6000
		               end
		          elseif (menuChoice == 0) then
		               maxDraw = (maxDraw + 1)
		               if (maxDraw > 400) then
		                    maxDraw = 400
		               end
		          end
		     elseif (event == EVT_MINUS_FIRST) or (event == 69) then
		          if (menuChoice == 1) then
		               battCap = battCap - 10
		               if (battCap < 10) then
		                    battCap = 10
		               end    
		          elseif (menuChoice == 0) then
		               maxDraw = maxDraw - 1
		               if (maxDraw < 1) then
		                    maxDraw = 1
		               end
		          end
		     elseif (menuChoice == 2) then -- Save values on transmitter
		          model.setGlobalVariable(0, 0, maxDraw)
                    model.setGlobalVariable(1, 0, (battCap/10))
		          endTime = endTimeCalc
		     end
		end

          if (event == EVT_ENTER_BREAK) then -- Toggle selection
               if (menuChoosen == 1) then
                    menuChoosen = 0
               else
                    menuChoosen = 1
               end
          elseif (event == EVT_EXIT_BREAK) then -- Always exit selection
               menuChoosen = 0
          end

		lcd.clear()

		lcd.drawScreenTitle(versionInfo,3,3)
		lcd.drawText(48,  10, "Flight Time Calculator")
		lcd.drawText(15,  20, "Max current draw : ")
		lcd.drawText(15,  30, "Battery capacity : ")
		lcd.drawText(15,  40, "End time : ",MIDSIZE)
		lcd.drawText(95, 40, ""..endTimeCalc.." s",MIDSIZE)

          --test
          --lcd.drawText(180, 42, ""..menuChoice..""..menuChoosen.."")

          if (menuChoosen == 1) then
               if (menuChoice == 2) then
                    lcd.drawText(160, 20, ""..maxDraw.." A")
                    lcd.drawText(160, 30, ""..battCap.." mAh")
                    lcd.drawText(160, 40, "saved",MIDSIZE+INVERS+BLINK)
               elseif (menuChoice == 1) then
                    lcd.drawText(160, 20, ""..maxDraw.." A")
                    lcd.drawText(160, 30, ""..battCap.." mAh",INVERS+BLINK)
                    lcd.drawText(160, 40, "save",MIDSIZE)
               else
                    lcd.drawText(160, 20, ""..maxDraw.." A",INVERS+BLINK)
                    lcd.drawText(160, 30, ""..battCap.." mAh")
                    lcd.drawText(160, 40, "save",MIDSIZE)
               end
          else
               if (menuChoice == 2) then
                    lcd.drawText(160, 20, ""..maxDraw.." A")
                    lcd.drawText(160, 30, ""..battCap.." mAh")
                    lcd.drawText(160, 40, "save",MIDSIZE+INVERS)
               elseif (menuChoice == 1) then
                    lcd.drawText(160, 20, ""..maxDraw.." A")
                    lcd.drawText(160, 30, ""..battCap.." mAh",INVERS)
                    lcd.drawText(160, 40, "save",MIDSIZE)
               else
                    lcd.drawText(160, 20, ""..maxDraw.." A",INVERS)
                    lcd.drawText(160, 30, ""..battCap.." mAh")
                    lcd.drawText(160, 40, "save",MIDSIZE)
               end
          end
          
		lcd.drawText(53, 55, "Press [MENU] to return",SMLSIZE)

     ---------------------------------
     -- Percentage menu
     ---------------------------------
	elseif (blnMenuMode == 1) then

		if event == 32 then
			--Take us out of menu mode
			blnMenuMode = 2
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

		lcd.drawScreenTitle(versionInfo,2,3)
		lcd.drawText(30, 10, "Set Percentage Notification")
		lcd.drawText(70, 20, "Every "..alertPerc.." %",MIDSIZE)
		lcd.drawText(66, 35, "Use +/- to change",SMLSIZE)

		lcd.drawText(36, 55, "Press [MENU] for more options",SMLSIZE)

     ---------------------------------
     -- Info/start screen
     ---------------------------------
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

		lcd.drawScreenTitle(versionInfo,1,3)

		lcd.drawGauge(6, 25, 70, 20, getValue('timer1') , endTime)
		lcd.drawText(135, 10, "End time : ",MIDSIZE)
		lcd.drawText(150, 25, ""..endTime.." s",MIDSIZE)
		lcd.drawText(130, 40, "Use +/- to change",SMLSIZE)

		lcd.drawText(36, 55, "Press [MENU] for more options",SMLSIZE)

		playAlerts()
          drawAlerts()
	end
end
--------------------------------

return {run=run_func, background=bg_func, init=init_func  }
