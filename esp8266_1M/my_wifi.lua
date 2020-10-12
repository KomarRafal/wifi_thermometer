--------------------------------------------------------------------------------
-- WiFi module for flash >= 1 MB and the newest nodeMCU
--------------------------------------------------------------------------------

local function init_wifi(self, ssid, pwd, call_back)
  wifi.setmode(wifi.STATION)
  wifi.sta.disconnect()
  wifi.sta.clearconfig()
  wifi.sta.config({ssid=ssid,
                 pwd=pwd,
--                 connect_cb=connected,
--                 disconnected_cb=disconnected,
                 got_ip_cb=call_back,
                 auto=true, save=false})
end

 -- Set module name as parameter of require and return module table
local M = {
  init_wifi = init_wifi
}
_G[modname or 'my_wifi'] = M
return M