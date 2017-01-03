This project is a Virtual Current Sensor LUA script for the OpenTX

* This project is mainly for Quadcopters without telemetry

Usage:

* Place the VCS.lua file on the SD/SCRIPTS/TELEMETRY
* Add the script as a telemetry screen

![Screenshot](images/ss_lua_script.png)

* Enable Timer1 as a TH% 00:00:00 timer

![Screenshot](images/ss_th_procent.png)

* Open the script with a long press on PAGE from standard screen

![Screenshot](images/ss_page1.png)

* Change warning interval on page 2

![Screenshot](images/ss_page2.png)

* Calculate Flight Time on page 3

![Screenshot](images/ss_ftc.png)

The timer should be reset by using a long ENTER press and reset the flight

![Screenshot](images/ss_reset.png)

How to determine the maximum current draw:

* Fly a battery, charge it and note the charged mah and flight time
* Max current draw = 1/(flight time/((charged mah/1000) * 3600))


I did rewrite some of the script, but all credit goes to the excellent KISS Telemetry script from DynamikAray 

( https://github.com/DynamikArray/KISS_Battery_Monitor )
