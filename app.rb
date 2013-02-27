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
session = nil 

get '/' do
    @blink = 'login'
    @btext = 'Write'
    @bclass = 'btn-primary'
    erb :index
end

get '/login' do
    session = DropboxSession.new(APP_KEY, APP_SECRET)
    session.get_request_token
    redirect authorize_url = session.get_authorize_url(URL)
end

get '/logout' do
    session.clear_access_token
    session = nil
    redirect '/'
end

get '/write' do

    redirect '/login' unless session != nil

    begin
        session.get_access_token
        @blink = 'logout'
        @btext = 'Log Out'
        @bclass =''
        erb :write
    rescue
        redirect '/login'
    end
end

post '/write' do

    redirect '/login' unless session != nil && session.authorized?

    entry = params[:entry]

    # figure out the name of the file for dropbox
    tm = Time.now

    dropFileName = tm.strftime("%Y-%m.%B") + ".markdown"
    heading = "**" + tm.strftime("%a %d at %l:%M%P") + "** -\t"
    big_heading = "#" + tm.strftime("%B %Y")

    tmpfile = Tempfile.new(dropFileName)

    #download the file if it exists
    begin
        client = DropboxClient.new(session, ACCESS_TYPE)
        oldfile = client.get_file(dropFileName)
        tmpfile.write(oldfile)
        tmpfile.write("  \n")
    rescue
        puts "File not found... Creating new one"
        tmpfile.write(big_heading+"  \n  \n")
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

    @blink = 'logout'
    @btext = 'Log Out'
    @bclass =''
    erb :write
end
