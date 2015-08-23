require 'adal'
require 'listen'
require 'net/http'
require 'uri'

ONEDRIVE_DIR = '/tmp/onedrive'

ADAL::Logging.log_level = ADAL::Logger::VERBOSE

AUTH_CTX = ADAL::AuthenticationContext.new
TENANT = 'adamajmichael'
RESOURCE = "https://#{TENANT}-my.sharepoint.com/"
CLIENT_ID = '066c3c1e-b904-4322-95f4-93decbefa9c7'
CLIENT_CRED = ADAL::ClientCredential.new(CLIENT_ID)

username = 'user1@adamajmichael.onmicrosoft.com'
password = 'Password123'

USER = ADAL::UserCredential.new(username, password)
BASE_URL = 'https://adamajmichael-my.sharepoint.com/_api/v1.0/me'

def access_token_for(user_cred)
  AUTH_CTX.acquire_token_for_user(RESOURCE, CLIENT_CRED, user_cred).access_token
end

def access_token
  access_token_for(USER)
end

def http(url)
  http = Net::HTTP.new(url.hostname, url.port)
  http.use_ssl = true
  http
end

##
# Uploads the file to OneDrive.
#
# @param String
def add2(fs_path)
  onedrive_path = fs_path.sub(/^#{ONEDRIVE_DIR}\//, '')
  puts "Attempting to write #{fs_path} to #{onedrive_path}"
  puts "It is #{File.read(fs_path)}"
  creation_url = URI('https://adamajmichael-my.sharepoint.com/_api/v1.0/me/files')
  creation_response = http(creation_url).post(
    creation_url,
    JSON.unparse({ 'name' => 'thing.txt', 'type' => 'File', 'file-path' => 'fruits'}),
    'authorization' => "Bearer #{access_token}",
    'content-type' => 'application/json')
  puts "The creation response is #{creation_response}"
  puts creation_response.body
  puts creation_response.code
  if creation_response.code != 200
    fail creation_response.inspect
  end
  puts "Now for"
  puts "#{JSON.parse(creation_response.body)['@odata.id']}/uploadcontent"
  upload_url =
    URI("#{JSON.parse(creation_response.body)['@odata.id']}/uploadcontent")
  upload_response = http(upload_url).post(
    upload_url,
    File.read(fs_path), 
    'authorization' => "Bearer #{access_token}")
  puts "The upload response is #{upload_response}"
end

def add(fs_path)
  onedrive_path = fs_path.sub(/^#{ONEDRIVE_DIR}\//, '')
  parentid = 6
  request_url = URI("#{BASE_URL}/files/getByPath('/Fruits')/children/add?name=thing")
  response = http(request_url).post(
    request_url,
    File.read(fs_path),
    'authorization' => "Bearer #{access_token}")
  puts response
  puts response.body
  puts response.code
end

def read_all
  request_url = URI("#{BASE_URL}/files/root?$expand=children")
  response = http(request_url).get(
    request_url,
    'authorization' => "Bearer #{access_token}")
  puts "Response is"
  puts response
  puts response.body
  puts response.code
  puts response.body.class
  puts JSON.parse(response.body).keys
end


##
# Updates the file on OneDrive.
#
# @param String
def update(fs_path)
  puts "Attempting to update #{fs_path}"
end

##
# Deletes the file on OneDrive.
#
# @param String
def remove(fs_path)
  puts "Attempting to remove #{fs_path}"
end

read_all
fail
listener = Listen.to(ONEDRIVE_DIR, debug: true) do |modified, added, removed|
  begin
    puts "Hmmm"
    puts modified.to_s
    puts added.to_s
    puts removed.to_s
    modified.each { |f| update f }
    added.each { |f| add f }
    removed.each { |f| remove f }
  rescue => e 
    puts "Shit"
    puts e.inspect
    puts e.backtrace
  end
end
listener.start
sleep
