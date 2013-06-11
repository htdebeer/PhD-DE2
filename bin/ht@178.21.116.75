require 'nokogiri'
require 'open-uri'


WEATHER_LOG_FILE = "/home/ht/primarycalculus/tue_weather_station.log"

tue_weather_station_url = "http://nadine.esrac.ele.tue.nl/"
tue_weather_station_page = Nokogiri::HTML(open(tue_weather_station_url))


current_weather_table = tue_weather_station_page.css('table:nth-of-type(2)')

_, _, time, _, day, month, year = current_weather_table.css('caption').inner_text.split(' ')
date = DateTime.strptime( "#{year}-#{month}-#{day} #{time}", '%Y-%B-%d %H:%M')

def strip_value( value )
    /[0-9]+(\.[0-9]+)?/.match(value) do |match|
        value = match.to_s
        break
    end
    value
end

categories = [:td_temperature_data, :td_rainfall_data, :td_wind_data, :td_pressure_data]

current_data = {}
label = ''

categories.each do |category|
    current_weather_table.css("tr.#{category} td").each do |cell|
        nbsp = Nokogiri::HTML("&nbsp;").text
        cell = cell.inner_text.gsub(nbsp, ' ')
        if label.empty?
            if cell.strip.empty?
                next
            else
                label = cell
            end
        else
            current_data[label] = strip_value cell
            label = ''
        end
    end
end


if not File.exists?(WEATHER_LOG_FILE)
    File.open( WEATHER_LOG_FILE, 'w') do |file|
        file.puts "date,time,#{current_data.keys.join(',')}"
    end
end


File.open( WEATHER_LOG_FILE, 'a') do |file|
    file.puts "#{date.strftime('%Y-%m-%d')},#{date.strftime('%H:%M')},#{current_data.values.join(',')}"
end
