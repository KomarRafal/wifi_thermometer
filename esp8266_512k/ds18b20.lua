--------------------------------------------------------------------------------
-- DS18B20 one wire module for 512 KB flash and nodeMCU 0.9.5
--------------------------------------------------------------------------------
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
local function read_temp(self, call_back, pin, unit, force_search)
  ow.setup(pin)
  self.sens = {}
  local addr = nil
  for i = 1, 5 do
    ow.reset_search(pin)
    addr = ow.search(pin)
    if (addr ~= nil) then break end
    tmr.delay(100000)
  end
  if (addr ~= nil) then
    crc = ow.crc8(string.sub(addr, 1, 7))
    if (crc == addr:byte(8)) then
      if ((addr:byte(1) == 0x10) or (addr:byte(1) == 0x28)) then
        ow.reset(pin)
        ow.select(pin, addr)
        ow.write(pin, 0x44, 1)
        tmr.delay(1000000)
        ow.reset(pin)
        ow.select(pin, addr)
        ow.write(pin, 0xBE, 1)
        local data = nil
        data = string.char(ow.read(pin))
        for i = 1, 8 do
          data = data .. string.char(ow.read(pin))
        end
        local crc = ow.crc8(string.sub(data, 1, 8))
        if (crc == data:byte(9)) then
          local temp = (data:byte(1) + data:byte(2) * 256)
          if (temp > 32768) then
            temp = (bxor(temp, 0xffff)) + 1
            temp = (-1) * temp
          end
          temp = temp * 625
          temp_integer = temp / 10000
          temp_fraction = (temp >= 0 and temp % 100) or (100 - temp % 100)
          self.sens[0] = string.format("%d.%02d", temp_integer, temp_fraction)
        end
      end
    end
  end
  if call_back then
    tmr.alarm(1, 10, 0, function() return call_back(ds18b20.sens) end)
  else
    if self.sens[0] then
      print(string.format("Temp: %s\n", self.sens[0]))
    else
      print("Sensor not found.\n")
    end
  end
end

 -- Set module name as parameter of require and return module table
local M = {
  sens = {},
  read_temp = read_temp
}
_G[modname or 'ds18b20'] = M
return M