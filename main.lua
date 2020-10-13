--[[
TODO:
- static IP, maybe in CONFIG_FILE
- web base wifi configurtion
- parameterize temperature field (outside, inside) (maybe from webpage?)
- blink led when connecting
]]--

if not BUTTON then
  BUTTON = false
end

local CONFIG_FILE = "eus_params.lua"
local WIFI_TIMEOUT = 20000
local OW_PIN = 3

local INSIDE = 1
local OUTSIDE = 2

local KEY_CHOPINA = "***REMOVED***"
local KEY_BRENNA = "***REMOVED***"

-- Uncomment it if you want to just see tempreature without sending
PRODUCTION = 0

if not PRODUCTION then
  PRODUCTION = 1
end
local SLEEP_TIME = 600000000
if PRODUCTION == 0 then
  SLEEP_TIME = 5000000
end

local function do_sleep()
  print(string.format("DeepSleep for %d [us]", SLEEP_TIME))
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
    conn:send("GET /update?key=" .. KEY_BRENNA .. "&field" .. INSIDE .. "=" .. temperature .. " HTTP/1.1\r\n")
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
  if PRODUCTION == 1 then
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
  IP, netmask, gateway = wifi.sta.getip()
  print(string.format("ip: %s, mask: %s, gw: %s", info.IP, info.netmask, info.gateway))
  wifi.eventmon.unregister(wifi.eventmon.STA_GOT_IP)
  meassure_temperatur()
end

local function wifi_timeout()
  print("WiFi timeout...")
  do_sleep()
end

local function check_button()
-- TODO:
  return BUTTON
end

local function configure_wifi()
  print("Configuring wifi...")
  enduser_setup.start(
    function()
      tmr.create():alarm(3000, tmr.ALARM_SINGLE, function()
        print("Connected to wifi as: " .. wifi.sta.getip())
        node.restart()
      end)
    end,
    function(err, str)
      print("enduser_setup: Err #" .. err .. ": " .. str)
    end,
    print -- Lua print function can serve as the debug callback
  )
end

local function factory_reset()
    print("Factory reset...")
    wifi.sta.disconnect()
    wifi.sta.clearconfig()
    file.remove(CONFIG_FILE)
    configure_wifi()
end


local function start()
  if check_button() then
    factory_reset()
  elseif not file.exists(CONFIG_FILE) then
    configure_wifi()
  else
    p = dofile(CONFIG_FILE)
    my_wifi = require("my_wifi")
    my_wifi:init_wifi(p.wifi_ssid, p.wifi_password, got_ip, 20000, wifi_timeout)
  end
end

start()