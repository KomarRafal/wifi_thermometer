local SSID = "***REMOVED***"
local PASSWORD = "***REMOVED***"
local OW_PIN = 3

local function panic(...)
  print("ERROR!".. ... .."Rebooting...\n\n")
  node.restart()
end

local function bxor(a, b)
    local r = 0
    for i = 0, 31 do
        if (a % 2 + b % 2 == 1) then
            r = r + 2 ^ i
        end
        a = a / 2
        b = b / 2
    end
    return r
end

--- Get temperature from DS18B20
local function get_temp()
  ow.reset_search(OW_PIN)
  local addr = ow.search(OW_PIN)
    
  if addr == nil then
    return nil
  end

  local crc = ow.crc8(string.sub(addr, 1, 7))
  if (crc == addr:byte(8)) then
    if ((addr:byte(1) == 0x10) or (addr:byte(1) == 0x28)) then
      ow.reset(OW_PIN)
      ow.select(OW_PIN, addr)
      ow.write(OW_PIN, 0x44, 1)
      tmr.delay(1000000)
      present = ow.reset(OW_PIN)
      ow.select(OW_PIN, addr)
      ow.write(OW_PIN, 0xBE, 1)
      local data = nil
      data = string.char(ow.read(OW_PIN))
      for i = 1, 8 do
        data = data .. string.char(ow.read(OW_PIN))
      end
      crc = ow.crc8(string.sub(data, 1, 8))
      if (crc == data:byte(9)) then
        local t = (data:byte(1) + data:byte(2) * 256)
        if (t > 32768) then
          t = (bxor(t, 0xffff)) + 1
          t = (-1) * t
        end
        t = t * 625
        return t
      end
    end
  end
  return nil    
end

local function send_temp(t1, t2)
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
    conn:send("GET /update?key=***REMOVED***&field2=" .. t1 .. "." .. string.format("%04d", t2) .. " HTTP/1.1\r\n")
    conn:send("Host: api.thingspeak.com\r\n")
    conn:send("Accept: */*\r\n")
    conn:send("User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n")
    conn:send("\r\n")
    conn:on(
        "sent",
        function(conn)
            print("Closing connection")
            conn:close()
        end
    )
    conn:on(
        "disconnection",
        function(conn)
            print("Got disconnection...")
        end
    )
end

local function handle_temp()
    local t1 = get_temp()
    if t1 == nil then return end
    local t2 = (t1 >= 0 and t1 % 10000) or (10000 - t1 % 10000)
    t1 = t1 / 10000
    print("Temp:" .. t1 .. "." .. string.format("%04d", t2) .. " C\n")
    if PRODUCTION == 1 then
      send_temp(t1, t2)
    end
end

local function meassure_temperatur()
  local temp_timer = tmr.create()
  if not temp_timer:alarm(TEMP_TIME, tmr.ALARM_AUTO, 
    function()
      handle_temp()
    end)
  then
    panic("ERROR")
  end
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
                 pwd=PASSWORD,
--                 connect_cb=connected,
--                 disconnected_cb=disconnected,
                 got_ip_cb=got_ip,
                 auto=true, save=false})
--  wifi.sta.config({ssid=SSID, pwd=PWD})
--  if not wifi_timer:alarm(1000, tmr.ALARM_AUTO,
--    function()
--      if wifi.sta.getip() == nil then 
--        print("IP unavaiable, Waiting...") 
--      else
--        wifi_timer:stop()
--        wifi_timer:unregister()
--        ip, netmask, gateway = wifi.sta.getip()
--        print("ip: "..ip.." netmask: "..netmask.." gateway: "..gateway.."\n")
--      end
--    end)
--  then
--    panic("ERROR")
--  end
end

local function start()
  if not PRODUCTION then
      PRODUCTION = 1
  end
  if PRODUCTION == 1 then
    TEMP_TIME = 120000
  else
    TEMP_TIME = 1000
  end
  init_wifi()
end

start()