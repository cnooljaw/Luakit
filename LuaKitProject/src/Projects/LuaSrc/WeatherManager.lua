local _weatherManager = {}

local Table = require('orm.class.table')
local _weatherTable = Table("weather")

_weatherManager.getWeather = function ()
	return _weatherTable.get:all():getPureData()
end

_weatherManager.parseWeathers = function (responseStr,callback)
	local t = cjson.decode(responseStr)
	local weatherTable = _weatherTable
	local ret = {}
	if t and t.weather and t.weather[1] and t.weather[1].future then
		weatherTable.get:delete()
		local city = t.weather[1].city_name
		for i,v in ipairs(t.weather[1].future) do
			local t = {}
			t.wind = v.wind
			t.date = v.date
			t.low = tonumber(v.low)
			t.high = tonumber(v.high)
			t.id = i
			t.city = city
			local weather = weatherTable(t)
			weather:save()
			table.insert(ret,weather:getPureData())
		end
	end
	if callback then
		callback(ret)
	end
end

_weatherManager.loadWeather = function (callback)
	lua.http.request({ url  = "http://tj.nineton.cn/Heart/index/all?city=CHSH000000",
		onResponse = function (response)
			if response.http_code ~= 200 then
				if callback then
					callback(nil)
				end
			else
				lua.thread.postToThread(BusinessThreadLOGIC,"WeatherManager","parseWeathers",response.response,function(data)
					if callback then
						callback(data)
					end
				end)
			end
		end})
end

return _weatherManager
