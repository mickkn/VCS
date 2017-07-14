--------------------------------------------------------------------------------
-- By Mick 29-01-2017
-- A virtual current sensor based on a throttle% timer in the OpenTX software
-- All credit goes to DynamikArray
-- https://github.com/DynamikArray/KISS_Battery_Monitor
--------------------------------------------------------------------------------

local versionInfo = "VC Sensor - v0.5"

local lastAlert = 0
local blnMenuMode = 0         -- Start menu in screen one

local endTime = 0             -- End time variable
local alertPerc = 10          -- Change if you want a different start percentage
local alertCounter = 0        -- Counter for the interval array
local alertEnable = 1         -- Overflow error fix
local alertDisable = 0        -- Full disable feature
local alertInterval = {}      -- Array with alert intervals
alertInterval[0] = 0          -- First place always zero

local TIMER = 'timer1'        -- Change if you want a different timer

local flyTime = 80
local battCapChrg = 1000
local maxDrawCalc = 0

local maxDraw = 0             -- Initialize max draw variable
local battCap = 0             -- Initialize battery capacity

local menuChoice = 0          -- Initialize menu choice in flight time calculator
local menuChoosen = 0         -- Initialize menu chosen in flight time calculator

-- OpenTX 2.0 - Percent Unit = 8 // OpenTx 2.1 - Percent Unit = 13
-- see: https://opentx.gitbooks.io/opentx-lua-reference-guide/content/general/playNumber.html
local percentUnit = 13

-----------------------------------------------------------------
-- Custom Functions & Utilities
-----------------------------------------------------------------
-- Rounding Function
local function round(val, decimal)
     local exp = decimal and 10^decimal or 1
     return math.ceil(val * exp - 0.5) / exp
end

-- Alert and Logging of last Value Played
local function playPerc(percVal)
     playNumber(percVal, percentUnit)
     playFile("/SOUNDS/en/system/percent0.wav") -- Only for OpenTX 2.2
     lastAlert = percVal -- Set lastAlert
end

-- Critical alert and Logging of last Value Played
local function playCritical(percVal)
     playFile("batcrit.wav")
     lastAlert = percVal -- Set lastAlert
end

-----------------------------------------------------------------
-- Playing alerts according to chosen percentage warning
-----------------------------------------------------------------
local function playAlerts()
     curTime = getValue(TIMER) -- Get current time in seconds

     if curTime == 0 then
          alertCounter = 0
          alertEnable = 1
     end

	percVal = round(((curTime/endTime) * 100),0) -- Percentage from current time

     if alertDisable == 0 then
          if percVal ~= lastAlert then
	          -- Alert the user we are in critical alert
	     	if percVal > 100 then
                    playCritical(percVal)
                    alertEnable = 0
	     	elseif percVal > 90 and percVal < 100 then
	     	     playPerc(percVal)
	     	elseif alertEnable == 1 then     
	     	     if percVal >= alertInterval[alertCounter] then
	     	          playPerc(alertInterval[alertCounter])
	     	          alertCounter = alertCounter + 1
	     	     end
               end
          end
     end     
end

-----------------------------------------------------------------
-- Update the percentage bar and time on screen
-----------------------------------------------------------------
local function drawAlerts()
     curTime = getValue(TIMER)

	percVal =  round(((curTime/endTime) * 100),0)
	lcd.drawText(5, 15, "USED: "..curTime.." s" , SMLSIZE)
     lcd.drawText(104, 30, percVal.." %" , SMLSIZE)
end

-----------------------------------------------------------------
-- Initial function
-----------------------------------------------------------------
local function init_func()
     maxDraw = model.getGlobalVariable(0, 0)  -- Get last maximum current draw in Amps
     battCap = model.getGlobalVariable(1, 0)*10  -- Get last battery capacity in mAh
     endTime = round((battCap/(maxDraw*1000))*60*60,0) -- Calculate end time
     
     ------------------------------------------------------------
     -- Initial values to some defaults if values is 0
     ------------------------------------------------------------
     if (maxDraw == 0) then
          maxDraw = 67
          battCap = 1300
          endTime = round((battCap/(maxDraw*1000))*60*60,0)
     end

     ------------------------------------------------------------
     -- Initial alert interval values
     ------------------------------------------------------------
     if alertPerc > 0 then
          for i=1, (100/alertPerc) do
               alertInterval[i] = (alertInterval[i-1] + alertPerc)
          end
     end

     playAlerts()
     drawAlerts()
end

-----------------------------------------------------------------
-- Background function
-----------------------------------------------------------------
local function bg_func()
     playAlerts()
end

-----------------------------------------------------------------
-- Run function
-----------------------------------------------------------------
local function run_func(event)
     ------------------------------------------------------------
     -- Max amp draw calculator
     ------------------------------------------------------------
     if blnMenuMode == 3 then
          
          if (event == 32) then -- Back to start screen
			blnMenuMode = 0
			-- Reset menu
			menuChoice = 0
			menuChoosen = 0
		end
     
          -- Calculate max current draw in amps
          maxDrawCalc = round((1/(flyTime/((battCapChrg/1000) * 3600))),0) -- in Amps
     
          -------------------------------------------------------
		-- Respond to user key presses
		-------------------------------------------------------
		if (menuChoosen == 0) then -- No options is selected with ENTER
		     if (event == EVT_ROT_LEFT) or (event == 69) then
                    menuChoice = menuChoice + 1
                    if (menuChoice > 1) then
                         menuChoice = 0
                    end
		     end
		     
		     if (event == EVT_ROT_RIGHT) or (event == 68) then
                    menuChoice = menuChoice - 1
                    if (menuChoice < 0) then
                         menuChoice = 1
                    end
		     end 
		else -- A option is selected with ENTER
		     if (event == EVT_ROT_RIGHT) or (event == 68) then
		          if (menuChoice == 1) then
		               battCapChrg = (battCapChrg + 1)
		               if (battCapChrg > 6000) then
		                    battCapChrg = 6000
		               end
		          elseif (menuChoice == 0) then
		               flyTime = (flyTime + 1)
		               if (flyTime > 400) then
		                    flyTime = 400
		               end
		          end
		     elseif (event == EVT_ROT_LEFT) or (event == 69) then
		          if (menuChoice == 1) then
		               battCapChrg = battCapChrg - 1
		               if (battCapChrg < 1) then
		                    battCapChrg = 1
		               end    
		          elseif (menuChoice == 0) then
		               flyTime = flyTime - 1
		               if (flyTime < 1) then
		                    flyTime = 1
		               end
		          end
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
          lcd.drawScreenTitle(versionInfo,4,4)
          
          lcd.drawText(1,  10, "Max Current Draw Calculator", SMLSIZE)
          lcd.drawText(5, 20, "TH% fly time: ", SMLSIZE)
		lcd.drawText(5, 30, "Charged mAh: ", SMLSIZE)
		lcd.drawText(5, 43, "Max current draw: ", SMLSIZE)
		
          if (menuChoosen == 1) then
               if (menuChoice == 1) then
                    lcd.drawText(80, 20, ""..flyTime.." s")
                    lcd.drawText(100, 30, ""..battCapChrg.." mAh",INVERS+BLINK)
               else
                    lcd.drawText(80, 20, ""..flyTime.." s",INVERS+BLINK)
                    lcd.drawText(80, 30, ""..battCapChrg.." mAh")
               end
          else
               if (menuChoice == 1) then
                    lcd.drawText(80, 20, ""..flyTime.." s")
                    lcd.drawText(80, 30, ""..battCapChrg.." mAh",INVERS)
               else
                    lcd.drawText(80, 20, ""..flyTime.." s",INVERS)
                    lcd.drawText(80, 30, ""..battCapChrg.." mAh")
               end
          end
          
          lcd.drawText(90, 40, ""..maxDrawCalc.." A",MIDSIZE)
          
          lcd.drawText(14, 55, "Press [MENU] to return",SMLSIZE)
          
     ------------------------------------------------------------
     -- Flight time calculator
     ------------------------------------------------------------
     elseif blnMenuMode == 2 then 

          if (event == 32) then -- To amp draw calculator
			blnMenuMode = 3
			-- Reset menu
			menuChoice = 0
			menuChoosen = 0
		end

          -- Calculate end time
          endTimeCalc = round((battCap/(maxDraw*1000))*60*60,0) -- in seconds

          -------------------------------------------------------
		-- Respond to user key presses
		-------------------------------------------------------
		if (menuChoosen == 0) then -- No options is selected with ENTER
		     if (event == EVT_ROT_LEFT) or (event == 69) then
                    menuChoice = menuChoice + 1
                    if (menuChoice > 2) then
                         menuChoice = 0
                    end
		     end
		     
		     if (event == EVT_ROT_RIGHT) or (event == 68) then
                    menuChoice = menuChoice - 1
                    if (menuChoice < 0) then
                         menuChoice = 2
                    end
		     end 
		else -- A option is selected with ENTER
		     if (event == EVT_ROT_RIGHT) or (event == 68) then
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
		     elseif (event == EVT_ROT_LEFT) or (event == 69) then
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

		lcd.drawScreenTitle(versionInfo,3,4)
		
		lcd.drawText(13,  10, "Flight Time Calculator", SMLSIZE)
		lcd.drawText(5,  20, "Max current draw: ", SMLSIZE)
		lcd.drawText(5,  30, "Battery capacity: ", SMLSIZE)
		lcd.drawText(5,  40, "End time: ", SMLSIZE)
		lcd.drawText(60,  40, ""..endTimeCalc.." s", SMLSIZE)

          if (menuChoosen == 1) then
               if (menuChoice == 2) then
                    lcd.drawText(87, 20, ""..maxDraw.." A", SMLSIZE)
                    lcd.drawText(87, 30, ""..battCap.." mAh", SMLSIZE)
                    lcd.drawText(87, 40, "saved", SMLSIZE+INVERS+BLINK)
               elseif (menuChoice == 1) then
                    lcd.drawText(87, 20, ""..maxDraw.." A", SMLSIZE)
                    lcd.drawText(87, 30, ""..battCap.." mAh",SMLSIZE+INVERS+BLINK)
                    lcd.drawText(87, 40, "save", SMLSIZE)
               else
                    lcd.drawText(87, 20, ""..maxDraw.." A",SMLSIZE+INVERS+BLINK)
                    lcd.drawText(87, 30, ""..battCap.." mAh", SMLSIZE)
                    lcd.drawText(87, 40, "save", SMLSIZE)
               end
          else
               if (menuChoice == 2) then
                    lcd.drawText(87, 20, ""..maxDraw.." A", SMLSIZE)
                    lcd.drawText(87, 30, ""..battCap.." mAh", SMLSIZE)
                    lcd.drawText(87, 40, "save",SMLSIZE+INVERS)
               elseif (menuChoice == 1) then
                    lcd.drawText(87, 20, ""..maxDraw.." A", SMLSIZE)
                    lcd.drawText(87, 30, ""..battCap.." mAh",SMLSIZE+INVERS)
                    lcd.drawText(87, 40, "save",SMLSIZE)
               else
                    lcd.drawText(87, 20, ""..maxDraw.." A",SMLSIZE+INVERS)
                    lcd.drawText(87, 30, ""..battCap.." mAh", SMLSIZE)
                    lcd.drawText(87, 40, "save",SMLSIZE)
               end
          end
          
		lcd.drawText(15, 55, "Press [MENU] for more",SMLSIZE)

     ------------------------------------------------------------
     -- Percentage menu
     ------------------------------------------------------------
	elseif (blnMenuMode == 1) then

		if event == 32 then -- To flight time calculator
			blnMenuMode = 2
			
			-- Update interval array
			if alertPerc > 0 then
			     for i=1, ((100/alertPerc)) do
			          alertInterval[i] = alertInterval[i-1] + alertPerc
			     end
			     alertDisable = 0
			else
			     alertDisable = 1
			end	
		end

		-- Respond to user KeyPresses for Setup
		if (event == EVT_ROT_RIGHT) or (event == 68) then
			alertPerc = alertPerc + 5
			if alertPerc >= 100 then
			     alertPerc = 100
			end
		end

		if (event == EVT_ROT_LEFT) or (event == 69) then
			alertPerc = alertPerc - 5
			if alertPerc <= 0 then
			     alertPerc = 0
			end
		end

		lcd.clear()

		lcd.drawScreenTitle(versionInfo,2,4)
		lcd.drawText(1, 10, "Set Percentage Notification",SMLSIZE)
		lcd.drawText(27, 23, "Every "..alertPerc.." %",MIDSIZE)
		lcd.drawText(24, 38, "Use +/- to change",SMLSIZE)

		lcd.drawText(15, 55, "Press [MENU] for more",SMLSIZE)

     ------------------------------------------------------------
     -- Info/start screen
     ------------------------------------------------------------
	else 
		if event == 32 then -- To percentage menu
			blnMenuMode = 1
		end

		-- Respond to user KeyPresses for Setup
		if (event == EVT_ROT_RIGHT) or (event == 68) then
			endTime = endTime + 1
			if endTime >= 9999 then
				endTime = 9999
			end
		end

		if (event == EVT_ROT_LEFT) or (event == 69) then
			endTime = endTime - 1
			if endTime <= 1 then
				endTime = 1
			end
		end


		--Update screen
		lcd.clear()

		lcd.drawScreenTitle(versionInfo,1,4)

		lcd.drawGauge(6, 25,90, 15, getValue('timer1') , endTime)
		lcd.drawText(60, 15, "End time: ",SMLSIZE)
		lcd.drawText(104, 15, ""..endTime.." s",SMLSIZE)
		lcd.drawText(25, 45, "Use +/- to change",SMLSIZE)

		lcd.drawText(15, 55, "Press [MENU] for more",SMLSIZE)

		playAlerts()
          drawAlerts()
	end
end

return {run=run_func, background=bg_func, init=init_func  }
