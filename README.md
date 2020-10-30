# wifi_thermometer

WiFi remote thermomether with thingspeak.com support.

## Hardware
- ESP8266 01
- DS18B20 with parasitic mode
- two switches

## Schematic
![alt text](https://github.com/KomarRafal/wifi_thermometer/blob/master/schematic.png?raw=true)


GPIO16 (D0) has to be connected with RST pin to enable wake up from deep sleep:

https://thingpulse.com/max-deep-sleep-for-esp8266/

## Files
- ```/main lua``` - main program, the file name has to be changed to init.lua for start after boot.
- ```/enduser_setup.html``` - configuration web page for end user setup
- ```/esp8266_512k/``` - files for ESP8266 with 512k flash
- ```/esp8266_512k/ds18b20.lua``` - minimal module for one DS18B20 sensor, it is copy of "LuaLoader/examples/DS18B20 One Wire Temperature server.lua" with some API adjustment
- ```/esp8266_512k/wifi.lua``` - module for handling wifi connection adjusted for NodeMCU 1.5.4.1-final API
- ```/esp8266_1M/``` - files recomendet for 1MB flash board version
- ```/esp8266_1M/ds18b20.lua``` - DS18B20 module, copied from: https://nodemcu.readthedocs.io/en/release/lua-modules/ds18b20/
- ```/esp8266_1M/wifi.lua``` - module for handling wifi connection adjusted for the newest release NodeMCU

## Requirements
NodeMCU with modules:
- end user setup
- file
- GPIO
- net
- node
- 1-Wire
- timer
- UART
- WIFI

## Preparing
1. Build NodeMCU with appropriate modules:
https://nodemcu-build.com/
2. Flash nodeMCU firmware on the ESP board: https://nodemcu.readthedocs.io/en/release/flash/
3. Copy files to the board:

- ```/init.lua``` - main.lua after name changed
- ```/ds18b20.lua``` - copied either from esp8266_1M or esp8266_512k folder
- ```/wifi.lua``` - copied either from esp8266_1M or esp8266_512k folder
- ```/enduser_setup.html```
## Production vs. Debug
TBD
## 512K flash version
TBD
## User guide
TBD
### Preparing ThingSpeak
### Factory reset
(LED blinking, web page, ThingSpeak, etc) - TBD
