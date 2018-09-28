#!/usr/bin/env ruby
require 'rest-client' # https://github.com/rest-client/rest-client
require 'json'
require 'dotenv/load'

# Configuration
server = ENV['SERVER']
creds = {
  handle: ENV['HANDLE'],
  password: ENV['PASSWORD']
}

# Log into Hashpass
# return: {JSON} hashpass authorization token
def login
  server = ENV['SERVER']
  creds = {
    handle: ENV['HANDLE'],
    password: ENV['PASSWORD']
  }
  puts "Logging in as #{ creds[:handle] }..."
  begin
    token = JSON.parse(RestClient.post(server + '/hplogin', creds.to_json, { content_type: :json, accept: :json }))['token']
    auth = { :Authorization => "Bearer #{token}" }
  rescue Errno::ECONNREFUSED, Net::ReadTimeout => e
    puts "Timeout (#{e}), retrying in 5 seconds..."
  rescue RestClient::ExceptionWithResponse => e  
    puts 'Error Logging in.'
    p e.response
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

 HPTOKEN = login
