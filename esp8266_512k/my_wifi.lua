--------------------------------------------------------------------------------
-- WiFi module for 512 KB flash and nodeMCU 0.9.5
--------------------------------------------------------------------------------
local function timeout(timeout_callback)
  tmr.stop(1)
  wifi.sta.disconnect()
  timeout_callback()
end

local function init_wifi(self, ssid, pwd, call_back, timeout_ms, timeout_callback)
  tmr.delay(1000000)
  if timeout_ms and timeout_callback then
    tmr.alarm(2, timeout_ms, 0, function() return timeout(timeout_callback) end)
  end
  print("Setting up WIFI...")
  wifi.sta.disconnect()
  wifi.setmode(wifi.STATION)
  wifi.sta.config(ssid, pwd)
  tmr.alarm(1, 1000, 1, function()
    if wifi.sta.getip() then
      tmr.stop(2)
      tmr.stop(1)
      ip, nm, gw = wifi.sta.getip()
      info = {IP = ip, netmask = nm, gateway = gw}
      if call_back then
        call_back(info)
      else
        print(string.format("got ip: %s, mask: %s, gw: %s", info.IP, info.netmask, info.gateway))
      end
      return
    end
  end)
end

 -- Set module name as parameter of require and return module table
local M = {
  init_wifi = init_wifi
}
_G[modname or 'my_wifi'] = M
return M