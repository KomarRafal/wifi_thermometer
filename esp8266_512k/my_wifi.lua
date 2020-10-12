--------------------------------------------------------------------------------
-- WiFi module for 512 KB flash and nodeMCU 0.9.5
--------------------------------------------------------------------------------

local function init_wifi(self, ssid, pwd, call_back)
  tmr.delay(1000000)
  print("Setting up WIFI...")
  wifi.sta.disconnect()
  wifi.setmode(wifi.STATION)
  wifi.sta.config(ssid, pwd)
  tmr.alarm(1, 1000, 1, function()
    if wifi.sta.getip() then
      ip, nm, gw = wifi.sta.getip()
      tmr.stop(1)
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