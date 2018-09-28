#!/usr/bin/env ruby
require 'rest-client' # https://github.com/rest-client/rest-client
require 'json'
require 'dotenv/load'
require 'uri'

# puts <<-'EOF'

# ██╗     ███████╗████████╗    ███╗   ███╗███████╗    ██╗███╗   ██╗██╗
# ██║     ██╔════╝╚══██╔══╝    ████╗ ████║██╔════╝    ██║████╗  ██║██║
# ██║     █████╗     ██║       ██╔████╔██║█████╗      ██║██╔██╗ ██║██║
# ██║     ██╔══╝     ██║       ██║╚██╔╝██║██╔══╝      ██║██║╚██╗██║╚═╝
# ███████╗███████╗   ██║       ██║ ╚═╝ ██║███████╗    ██║██║ ╚████║██╗
# ╚══════╝╚══════╝   ╚═╝       ╚═╝     ╚═╝╚══════╝    ╚═╝╚═╝  ╚═══╝╚═╝

# --[ WIFI Connection Manager ]--------

# EOF

# Arguments
if ARGV.include?(['-help', '-h', '--help', '--h']) || ARGV.empty?
  puts <<-'EOF'

  ---------------------------------------------------------
   FLAGS

     Ussage:    letmein.rb SSID

     --fetch    download a wpa_supplicant.conf for the specified SSID    
  
  ---------------------------------------------------------

  EOF
end
puts "Error: SSID required." if ARGV.empty?


server = ENV['SERVER']
creds = {
  handle: ENV['HANDLE'],
  password: ENV['PASSWORD']
}
content_type = { content_type: :json, accept: :json }
timestamp = DateTime.now.to_json


def login
  server = ENV['SERVER']
  creds = {
    handle: ENV['HANDLE'],
    password: ENV['PASSWORD']
  }
  puts "Logging in as #{ creds[:handle] }..."
  begin
    p token = JSON.parse(RestClient.post(server + '/hplogin', creds.to_json, { content_type: :json, accept: :json }))['token']
    p auth = { :Authorization => "Bearer #{token}" }
  rescue Errno::ECONNREFUSED, Net::ReadTimeout => e
    puts "Timeout (#{e}), retrying in 5 seconds..."
    # sleep 5
  rescue RestClient::ExceptionWithResponse => e  
    puts 'Error Logging in.'
    p e.response
    # sleep 5
  rescue RestClient::Unauthorized, RestClient::Forbidden => e
    puts 'Access denied'.red
    p e.response
  rescue => e
    puts 'Error logging in'
    p e
    sleep 5
    retry
   end
   auth
 end


auth = login
ssid = ARGV.last
server = ENV['SERVER']
file = RestClient.get(server + "/wpa/#{ URI::encode(ssid) }", auth.merge({ content_type: :json, accept: :json }))

if file.code == 200
  psk = file.body.split("\n").grep(/psk/)[0].split('"').last
  filename = ssid.gsub(/[^0-9A-Za-z]/, '')
  puts "SSID:\t #{ ssid }"
  puts "PSK:\t #{ psk }"
  File.write("/root/git/letmein/networks/#{ filename }_wpa_supplicant.conf", file.body)
  puts "👌\t Saved: networks/#{ filename }_wpa_supplicant.conf\n\n"
  
else
  puts "😩 Unable to find password for #{ ssid }."
  exit!
end

puts 'Done.'
