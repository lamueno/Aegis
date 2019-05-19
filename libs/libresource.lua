local mod = aegis
local me = {}
mod.libresource = me


me.rolling_average = function(old, delta_value, delta_time, interval, weight)
  return ( old * max(interval - weight * delta_time, 0) + weight * delta_value ) / interval
end

-- Meta Health Class
me.Resource = { }
me.Resource.__index = me.Resource

function me.Resource.new(init, interval, weight)
  
  local self = setmetatable({}, me.Resource)
  local now = GetTime()
  self.now = init
  self.old = init
  self.last_gain = now
  self.last_loss = now
  self.gps = 0
  self.gps_max = 0
  self.lps = 0
  self.lps_max = 0
  self.interval = interval or 15
  self.weight= weight or 2
  return self

end

function me.Resource:onevent()

	local now = GetTime()
	local delta_value = self.now - self.old
	self.old = self.now

	if delta_value > 0 then
		local delta_time = now - self.last_gain
		self.last_gain = now

		self.gps = me.rolling_average(self.gps, delta_value, delta_time, self.interval, self.weight)

		if self.gps > self.gps_max then
			self.gps_max = self.gps
		end

	elseif delta_value < 0 then
		delta_value = -delta_value 
		local delta_time = now - self.last_loss
		self.last_loss = now

		self.lps = me.rolling_average(self.lps, delta_value, delta_time, self.interval, self.weight)

		if self.lps > self.lps_max then
			self.lps_max = self.lps
		end
	end
end

function me.Resource:onupdate()

	local now = GetTime()

	if now - self.last_gain > self.interval / 3 then
		self.gps = me.rolling_average(self.gps, 0, self.interval/3, self.interval, self.weight)
	end

	if now - self.last_loss > self.interval / 3 then
		self.lps = me.rolling_average(self.lps, 0, self.interval/3, self.interval, self.weight)
	end

	if self.gps < 0.1 and self.gps_max > 0 then
		self.gps_max = 0
	end

	if self.lps < 0.1 and self.lps_max > 0 then
		self.lps_max = 0
	end

end

function me.Resource:predict(in_seconds)
  return self.now + (self.gps - self.lps) * in_seconds
end

function me.Resource:exhaust()
	if self.gps < self.lps then
		return self.now / (self.lps - self.gps) + GetTime()
	end
end