# wifi_thermometer

WiFi remote thermomether with thingspeak.com support.

## Hardware
- ESP8266 01
- DS18B20 with parasitic mode
- two switches

## Schematic
![schematic](https://github.com/KomarRafal/wifi_thermometer/blob/master/schematic.png?raw=true)


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
## Testing mode
In testing mode measured temperature is not sent to thingspeak server. Sleep time is shorter.
Device does sequence (if not in factory reset mode):
1. wake up
2. connect to wifi AP
3. measure temperature
4. Sleep for 5s

To enable testing mode in file ```init.lua``` uncomment:
```
-- TESTING = 1
```

## 512K flash version
ESP8266 was tested with 1MB of flash as well as 512KB. To use 512K version files from ```esp8266_512k``` folder have to be used.
There are two different approaches that can be applied:
### full functionality
1. Build NodeMCU with appropriate modules for 512KB flash (https://nodemcu-build.com/):

```1.5.4.1-final (frozen, for 512KB flash)```

2. Flash nodeMCU firmware on the ESP board: https://nodemcu.readthedocs.io/en/release/flash/
3. Copy files to the board:
- ```/init.lua``` - main.lua after name changed
- ```/ds18b20.lua``` - copied from esp8266_512k folder
- ```/wifi.lua``` - copied from esp8266_512k folder
- ```/enduser_setup.html```

In my case there were two issues which I could not handle:
1. wifi connection was not always established and was unstable
2. I could not send data to thingspeak
### limited functionality
Limited functionality works better on 512K board version. But there are some limitations. Unfortunately, this version does not work with a web-based configurator and requires manual adding all configuration fields. Also, buttons are not needed, those don't work.
1. Use default NodeMCU provided with ESP flasher: https://github.com/nodemcu/nodemcu-flasher
2. Checkout tag: ```512K_FINAL```
3. Change all fields: ```***PUT_YOUR_XXX***``` to desired values in ```mina.lua```. You can also adjust ```SLEEP_TIME``` in [us]
4. Copy files to the board:
- ```/init.lua``` - main.lua after name changed
- ```/ds18b20.lua``` - copied from esp8266_512k folder
- ```/wifi.lua``` - copied from esp8266_512k folder

In my case, this works fine. But after many hours it stopped, I don't know why.
## User guide
### Preparing ThingSpeak
Create a free account on https://thingspeak.com. After login to ThingSpeak go to ```Channels -> My Channels```. Create a new channel ```New Channel``` (which can be either public or private). After a successful channel creation go to ```Channels -> My Channels -> Your created channel -> API Keys```. Copy ```Write API Key```.
### Activity diagram
![Activity-diagram](http://www.plantuml.com/plantuml/proxy?cache=no&src=https://raw.githubusercontent.com/KomarRafal/wifi_thermometer/master/activity_uml.iuml)

### Sleep
Most of the time device is sleeping. WiFi radio is turned off to save energy. You can set up different durations of sleeping comparing the accuracy of measurement versus device lifetime. While sleeping device can be wake up only by pressing the ```HW_RST``` button or toggling power.

### Reset
```HW_RST``` button is connected directly to the reset pin. It is used to wake up the device and start ```Running``` mode (or ```Configuration``` mode). It can be used to force sending new data to the ThingSpeak server without waiting for sleep to be ended.

### Factory reset
A factory reset is performed by holding the ```Factory Reset``` button for about 4 seconds while running. The issue is that the device sleeps almost all the time and while sleeping ```Factory Reset``` button is inactive. So first you have to wake up the device by clicking ```HW_RST``` button (hardware reset - connected directly to reset pin) or by power toggling.

Factory reset mode cleans all configuration from memory:

- WiFi SSID
- WiFi Password
- ThingSpeak Key
- ThingSpeak Field
- sleep time

After the factory reset device is switched to ```configuration``` mode.

### Configuration
In ```Configuration``` mode blue LED blinks with a one-second period (applies only to ESP 8266-01 board without "S" postfix).

It is used to set up device parameters:

- WiFi SSID
- WiFi Password
- ThingSpeak Key
- ThingSpeak Field
- sleep time

In this mode device behaves as WiFi access point with SSID: ```SetupGadget_XXX``` where ```XXX``` is device unique serial number.

- connect your PC/SmartPhone to device AP:

![wifi_AP](https://github.com/KomarRafal/wifi_thermometer/blob/master/wifi.png?raw=true)

- using web browser navigate to ```192.168.4.1```
- fille in configuration fields (you can scan available access points - ```Scan for Networks```):
  - ```Wi-Fi Name``` - AP name
  - ```Password```
  - ```ThingSpeak write API key``` - from your ThingSpeak channel
  - ```ThingSpeak field number``` - from your ThingSpeak channel
  - ```Sleep time``` - can be either 10min, 15min or 30min
- click ```Save```

![configuration](https://github.com/KomarRafal/wifi_thermometer/blob/master/config.png?raw=true)

- after successfully connected to the WiFi access point device will switch to ```Running``` mode:

![connected](https://github.com/KomarRafal/wifi_thermometer/blob/master/wifi_connected.png?raw=true)

### Running

In normal operating device wakes up after the demand amount of minutes. First, it tries to connect to the configured access point. There is a 20-second timeout. If the connection is not established until the timeout is reached the device is reset.

After the connection is established device tries to connect to the temperature sensor. If there is no sensor the device is reset.

After a successful sensor read the temperature is sent to the ThingSpeak server with a configured write key and field number.

No matter whether the temperature was sent correctly or server timeouts the device is going to sleep.
