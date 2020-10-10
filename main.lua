--[[
TODO:
- static IP
- web base wifi configurtion
- parameterize temperature channel
]]--

local SSID = "***REMOVED***"
local PASSWORD = "***REMOVED***"
local OW_PIN = 3

local INSIDE = 1
local OUTSIDE = 2

if not PRODUCTION then
  PRODUCTION = 1
end
local SLEEP_TIME = 600000000
if PRODUCTION == 0 then
  SLEEP_TIME = 5000000
end
  
local function panic(...)
  print("ERROR!".. ... .."Rebooting...\n\n")
  node.restart()
end

local function do_sleep()
  print(string.format("DeepSleep for %d [us]",SLEEP_TIME))
  node.dsleep(SLEEP_TIME, 3)
end

local function send_temp(temperature)
    -- conection to thingspeak.com
    print("Sending data to thingspeak.com")
    conn = net.createConnection(net.TCP, 0)
    conn:on(
        "receive",
        function(conn, payload)
            print(payload)
        end
    )
    -- api.thingspeak.com 184.106.153.149
    conn:connect(80, "184.106.153.149")
    conn:send("GET /update?key=***REMOVED***&field" ..OUTSIDE.. "=" .. temperature .. " HTTP/1.1\r\n")
    conn:send("Host: api.thingspeak.com\r\n")
    conn:send("Accept: */*\r\n")
    conn:send("User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n")
    conn:send("\r\n")
    conn:on(
        "sent",
        function(conn)
            print("Closing connection")
            conn:close()
            do_sleep()
        end
    )
    conn:on(
        "disconnection",
        function(conn)
            print("Got disconnection...")
            do_sleep()
        end
    )
end

local function handle_temp(temp)
  if #ds18b20.sens == 0 then
    print("Sensor not found.")
    do_sleep()
    return
  end  
  for addr, temp in pairs(temp) do
    temperature = temp
  end
  print(string.format("Temp: %s C", temperature))
  if PRODUCTION == 1 then
    send_temp(temperature)
  else
    do_sleep()
  end
end

local function meassure_temperatur()
  ds18b20 = require("ds18b20")
  ds18b20:read_temp(handle_temp, pin, ds18b20.C, nil)
end

local function got_ip(info)
     print(string.format("got ip: %s, mask: %s, gw: %s", info.IP, info.netmask, info.gateway))
     wifi.eventmon.unregister(wifi.eventmon.STA_GOT_IP)
     got_ip=nil
     meassure_temperatur()
end

local function init_wifi()
  local wifi_timer = tmr.create()
  wifi.setmode(wifi.STATION)
  wifi.sta.disconnect()
  wifi.sta.clearconfig()
  wifi.sta.config({ssid=SSID,
                 pwd="***REMOVED***",
--                 connect_cb=connected,
--                 disconnected_cb=disconnected,
                 got_ip_cb=got_ip,
                 auto=true, save=false})
end

local function start()
  init_wifi()
end

start()