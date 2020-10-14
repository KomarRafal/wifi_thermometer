--------------------------------------------------------------------------------
-- WiFi module for flash >= 1 MB and the newest nodeMCU
--------------------------------------------------------------------------------
local function timeout(timeout_callback)
  wifi.sta.disconnect()
  timeout_callback()
end

local function init_wifi(self, ssid, pwd, call_back, timeout_ms, timeout_callback)
  if timeout_ms and timeout_callback then
    tmr.create():alarm(timeout_ms, tmr.ALARM_SINGLE, function() return timeout(timeout_callback) end)
  end
  print("Setting up WiFi...")
  wifi.setmode(wifi.STATION)
  wifi.sta.config({ssid=ssid,
                 pwd=pwd,
--                 connect_cb=connected,
--                 disconnected_cb=disconnected,
                 got_ip_cb=call_back,
                 auto=true, save=true})
end

 -- Set module name as parameter of require and return module table
local M = {
  init_wifi = init_wifi
}
_G[modname or 'my_wifi'] = M
return M