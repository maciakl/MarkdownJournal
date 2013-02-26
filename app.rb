require 'sinatra'
require 'tempfile'
require 'yaml'
require 'dropbox_sdk'

config = YAML::load(File.open('config.yml'))

APP_KEY = config['key']
APP_SECRET = config['secret']
URL = config['url']
ACCESS_TYPE = :app_folder

#enable :sessions
session = DropboxSession.new(APP_KEY, APP_SECRET)

get '/' do
    @btn = 'login'
    erb :index
end

get '/login' do
    session.get_request_token
    redirect authorize_url = session.get_authorize_url(URL)
end

get '/logout' do
    session.clear_access_token
    redirect '/'
end

get '/write' do
    begin
        session.get_access_token
        @btn = 'logout'
        erb :write
    rescue
        redirect '/login'
    end
end

post '/write' do

    redirect '/login' unless session.authorized?
    entry = params[:entry]

    # figure out the name of the file for dropbox
    tm = Time.now

    dropFileName = tm.strftime("%Y-%m.%B") + ".markdown"
    heading = "**" + tm.strftime("%a %d %l:%M%P") + "** "

    tmpfile = Tempfile.new(dropFileName)

    #download the file if it exists
    begin
        client = DropboxClient.new(session, ACCESS_TYPE)
        oldfile = client.get_file(dropFileName)
        tmpfile.write(oldfile)
        tmpfile.write("\r\n")
    rescue
        puts "File not found... Creating new one"
    end 
    
    # append the entry to the end of the file
    tmpfile.write(heading)
    tmpfile.write(entry)
    tmpfile.close

    # Drobpbox upload
    tmpfile.open
    response = client.put_file("/"+dropFileName, tmpfile, true)
    puts "uploaded: ", response.inspect

    

    tmpfile.close
    tmpfile.unlink

    erb :write
end
