--[[
TODO:
-- handle empty thingspeak key and empty field nbr
]]--

local CONFIG_FILE = "eus_params.lua"
local WIFI_TIMEOUT = 20000
local OW_PIN = 3
local LED_PIN = 10
local BUTTON_PIN = 4
local UART_BAUDRATE = 115200

local config = nil

-- Uncomment it if you want to just see tempreature without sending
-- TESTING = 1

if not TESTING then
  TESTING = 0
end

local function do_sleep()
  local sleep_time = config.sleep_time
  if TESTING == 1 then
    sleep_time = 5000000
  end

  print(string.format("DeepSleep for %d [us]", sleep_time))
  node.dsleep(sleep_time, 3)
end

-- GPIO module? pin as module member
local TIMER_COUNT = 3
local button_pin = BUTTON_PIN 
local function check_button()
  if gpio.read(button_pin) == 1 then
    return false
  end
  for i = 0, TIMER_COUNT do
    print("Button preset...")
    tmr.delay(1000000)
    if gpio.read(button_pin) == 1 then
      return false
    end
  end
  print("Button confirmed!")
  return true
end

local function setup_gpio_factory_reset()
  gpio.mode(button_pin, gpio.INPUT, gpio.PULLUP)
end

local function button_int_handler(level, when, eventcount)
  print("INT...")
  setup_gpio_factory_reset()
  if not tmr.create():alarm(500, tmr.ALARM_SINGLE, function()
      node.restart()
    end)
  then
    node.restart()
  end
end


local function setup_gpio_restart()
  gpio.mode(button_pin, gpio.INT, gpio.PULLUP)
  gpio.trig(button_pin, "down", button_int_handler)
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
    conn:send("GET /update?key=" .. config.write_key .. "&field" .. config.field_nbr .. "=" .. temperature .. " HTTP/1.1\r\n")
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

local function led_blink()
  local pin = gpio.read(LED_PIN)
  pin = pin == 1 and 0 or pin == 0 and 1
  gpio.write(LED_PIN, pin)
end

-- LED is connected with TX0 on board,
-- blinking will stop transmitting on UART
local function start_blinking(period)
  blink_timer = tmr.create()
  if blink_timer then
    gpio.mode(LED_PIN, gpio.OUTPUT, gpio.PULLUP)
    blink_timer:alarm(period, tmr.ALARM_AUTO, function()
      led_blink()
    end)
  end
end

local function stop_blinking()
  if blink_timer then
    blink_timer.unregister()
    blink_timer = nil
  end
    uart.setup(0, UART_BAUDRATE, 8, uart.PARITY_NONE, uart.STOPBITS_1, 1)
end

local function got_ip(info)
  stop_blinking()
  IP, netmask, gateway = wifi.sta.getip()
  print(string.format("ip: %s, mask: %s, gw: %s", info.IP, info.netmask, info.gateway))
  wifi.eventmon.unregister(wifi.eventmon.STA_GOT_IP)
  meassure_temperatur()
end

local function wifi_timeout()
  print("WiFi timeout...")
  do_sleep()
end

local function configure_wifi()
  print("Configuring wifi...")
--  Watchdog
  tmr.create():alarm(300000, tmr.ALARM_SINGLE, function()
      node.restart()
    end)
  start_blinking(500)
--  wifi.setmode(wifi.STATIONAP)
--  wifi.ap.config({ssid="TermometrWiFi", auth=wifi.OPEN})
--  enduser_setup.manual(true)
  enduser_setup.start(
    function()
      print("Connected to wifi as: " .. wifi.sta.getip())
      tmr.create():alarm(3000, tmr.ALARM_SINGLE, function()
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
  uart.setup(0, UART_BAUDRATE, 8, uart.PARITY_NONE, uart.STOPBITS_1, 1)
  setup_gpio_factory_reset()
  if check_button() or not file.exists(CONFIG_FILE) then
    factory_reset()
  else
    setup_gpio_restart()
    config = dofile(CONFIG_FILE)
    my_wifi = require("my_wifi")
    my_wifi:init_wifi(config.wifi_ssid, config.wifi_password, got_ip, WIFI_TIMEOUT, wifi_timeout)
  end
end

start()
