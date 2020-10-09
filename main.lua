local SSID = "***REMOVED***"
local PWD = "***REMOVED***"

local function panic(...)
  print("ERROR!".. ... .."Rebooting...\n\n")
  node.restart()
end

local function init_wifi()
  local wifi_timer = tmr.create()
  wifi.setmode(wifi.STATION)
  wifi.sta.disconnect()
  wifi.sta.clearconfig()
  wifi.sta.config({ssid=SSID, pwd=PWD})
  wifi.sta.connect()
  if not wifi_timer:alarm(1000, tmr.ALARM_AUTO,
    function()
      if wifi.sta.getip() == nil then 
        print("IP unavaiable, Waiting...") 
      else
        wifi_timer:stop()
        wifi_timer:unregister()
        ip, netmask, gateway = wifi.sta.getip()
        print("ip: "..ip.." netmask: "..netmask.." gateway: "..gateway.."\n")
      end
    end)
  then
    panic("ERROR")
  end
end

local function main()
  init_wifi()
  print("DUPA\n")
--  print("ip: "..ip.." netmask: "..netmask.." gateway: "..gateway.."\n")
end

main()