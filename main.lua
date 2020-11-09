--[[
-- If you face a lack of memory in 512KB of flash
-- try to comment out below variables 
-- and copy values directly to the source code
--]]
local SSID = "***PUT_YOUR_SSID***"
local PASSWORD = "***PUT_YOUR_PWD***"
local WIFI_TIMEOUT = 20000
local OW_PIN = 3
--
local FIELD = "***PUT_YOUR_FIELD_NBR***"
local KEY = "***PUT_YOUR_KEY***"

-- Uncomment it if you want to just see tempreature without sending
--TESTING = 1

if not TESTING then
  TESTING = 0
end
local SLEEP_TIME = 600000000
if TESTING == 1 then
  SLEEP_TIME = 5000000
end

local function do_sleep()
  print(string.format("DeepSleep for %d [us]", SLEEP_TIME))
  node.dsleep(SLEEP_TIME, 3)
end

local function send_temp(temperature)
    -- conection to thingspeak.com
--    print("Sending data to thingspeak.com")
    conn = net.createConnection(net.TCP, 0)
    conn:on(
        "receive",
        function(conn, payload)
            print(payload)
        end
    )
    -- api.thingspeak.com 184.106.153.149
    conn:connect(80, "184.106.153.149")
    conn:send("GET /update?key=" .. KEY .. "&field" .. FIELD .. "="..temperature.." HTTP/1.1\r\n")
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
  package.loaded["ds18b20"] = nil
  local sensor_found = false 
  for addr, temp in pairs(temp) do
    temperature = temp
    sensor_found = true
  end
  if not sensor_found then
    print("Sensor not found.")
    do_sleep()
    return
  end
  print(string.format("Temp: %s C", temperature))
  if TESTING == 0 then
    send_temp(temperature)
  else
    do_sleep()
  end
end

local function meassure_temperatur()
  ds18b20 = require("ds18b20")
  ds18b20:read_temp(handle_temp, OW_PIN, ds18b20.C, nil)
end

local function got_ip(info)
     print(string.format("ip: %s, mask: %s, gw: %s", info.IP, info.netmask, info.gateway))
     package.loaded["my_wifi"] = nil
     meassure_temperatur()
end

local function wifi_timeout()
  print("WiFi timeout...")
  do_sleep()
end

local function start()
  my_wifi = require("my_wifi")
  my_wifi:init_wifi(SSID, PASSWORD, got_ip, WIFI_TIMEOUT, wifi_timeout)
end

start()