#!/usr/bin/env ruby

require 'adal'
require 'highline/import'
require 'onedrive_for_business'

ONEDRIVE_DIR = ARGV[0] || '/tmp/onedrive'

ADAL::Logging.log_level = ADAL::Logger::FATAL

AUTH_CTX = ADAL::AuthenticationContext.new
TENANT = 'adamajmichael'
RESOURCE = "https://#{TENANT}-my.sharepoint.com/"
CLIENT_ID = '066c3c1e-b904-4322-95f4-93decbefa9c7'
CLIENT_CRED = ADAL::ClientCredential.new(CLIENT_ID)

username = ask("Username: ")
password = ask("Password: ") { |p| p.echo = "*" }

USER = ADAL::UserCredential.new(username, password)

def access_token
  AUTH_CTX.acquire_token_for_user(RESOURCE, CLIENT_CRED, USER).access_token
end

def update
  drive = OneDriveForBusiness::Drive.new('adamajmichael', access_token)
  files = OneDriveForBusiness::Folder.get_by_path(drive, '/').contents!.each do |file|
    full_path = "#{ONEDRIVE_DIR}#{file.parent_reference.path}#{file.name}"
    File.write(full_path, file.download!) unless File.exist?(full_path) || file.download!.empty?
  end
end

if access_token
  puts "Daemon started"
  Thread.new do
    while true do
      begin
        update
      rescue => e
        puts e
        puts e.backtrace
      end
      sleep 1
    end
  end
  sleep
else
  puts "Failed to authenticate"
end
