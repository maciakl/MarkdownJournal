require 'sinatra'
require 'tempfile'
require 'yaml'
require 'dropbox_sdk'
require 'active_support/core_ext/integer/inflections'

config = YAML::load(File.open('config.yml'))

APP_KEY = config['key']
APP_SECRET = config['secret']
URL = config['url']
ACCESS_TYPE = :app_folder

#enable :sessions
session = nil 

get '/' do
    @blink = 'login'
    @btext = '<i class="icon-edit icon-white"></i> Write'
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

    redirect '/write' if entry.empty?

    # figure out the name of the file for dropbox
    tm = Time.now

    dropFileName = tm.strftime("%Y-%m.%B") + ".markdown"

    # Define the headings:

    # Time of post
    heading = "**" + tm.strftime("%l:%M%P") + "** -\t"
    # Day of the week
    daily_heading = "##" + tm.strftime("%A") + " the " + tm.day.ordinalize
    # Month and year
    big_heading = "#" + tm.strftime("%B %Y")

    tmpfile = Tempfile.new(dropFileName)

    #download the file if it exists
    begin
        client = DropboxClient.new(session, ACCESS_TYPE)
        oldfile = client.get_file(dropFileName)
        tmpfile.write(oldfile)
        tmpfile.write("  \r\n  \r\n")
    rescue
        puts "File not found... Creating new one"
        tmpfile.write(big_heading+"  \r\n  \r\n")
    end 
    
    # include daily heading if it is not in already
    tmpfile.write(daily_heading + "  \r\n  \r\n") unless ( oldfile != nil && oldfile.include?(daily_heading) )

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

get '/about' do
    erb :about
end

get '/contact' do
    erb :contact
end
