require 'sinatra'
require 'tempfile'
require 'yaml'
require 'dropbox_sdk'
require 'active_support/core_ext/integer/inflections'
require 'active_support/time'

#YAML::ENGINE.yamler= 'syck'
config = YAML::load_file('config.yml')

APP_KEY = config['key']
APP_SECRET = config['secret']
URL = config['url']
ACCESS_TYPE = :app_folder


enable :sessions

get '/' do
    @blink = 'write'
    @btext = '<i class="icon-edit icon-white"></i> Write'
    @bclass = 'btn-primary'
    erb :index
end

get '/login' do
    # Create dropbox session object and serialize it to the Sinatra session
    dropbox_session = DropboxSession.new(APP_KEY, APP_SECRET)
    dropbox_session.get_request_token
    session[:dropbox] = dropbox_session.serialize()

    # redirect user to Dropbox auth page
    redirect authorize_url = dropbox_session.get_authorize_url(URL)
end

get '/logout' do
    # destroy session array
    session[:dropbox] = nil
    redirect '/'
end

get '/write' do

    redirect '/login' unless session[:dropbox] != nil

    # deserialize DropboxSession from Sinatra session store
    dropbox_session = DropboxSession::deserialize(session[:dropbox])

    # check if user authorized via the web link (has access token)
    # redirect to login page if not
    begin
        dropbox_session.get_access_token
        
        # serialize for future use
        session[:dropbox] = dropbox_session.serialize();
        @blink = 'logout'
        @btext = 'Log Out'
        @bclass =''
        erb :write
    rescue
        redirect '/login'
    end
end

post '/write' do

    # make sure the user authorized with Drobox
    redirect '/login' unless session[:dropbox] 
    
    # get DropboxSession out of Sinatra session store again
    dropbox_session = DropboxSession::deserialize(session[:dropbox])

    # make sure it still has access token
    redirect 'login' unless dropbox_session.authorized?

    entry = params[:entry]

    # if empty string was submitted, do nothing
    redirect '/write' if entry.empty?

    # Set timezone to EST because main server is set to PST time
    Time.zone = "Eastern Time (US & Canada)"
    tm = Time.zone.now
        
    # figure out the name of the file for dropbox
    # Default format is YYYY-MM-Monthname.markdown
    dropFileName = tm.strftime("%Y-%m.%B") + ".markdown"

    # Define the default headings 
    
    # Month and year - goes at the top of a new document
    big_heading = "#" + tm.strftime("%B %Y")
    
    # Day of the week - only included once per day
    daily_heading = "##" + tm.strftime("%A") + " the " + tm.day.ordinalize
    
    # Time-stamp for each entry
    heading = "**" + tm.strftime("%l:%M%P") + "** -\t"

    tmpfile = Tempfile.new(dropFileName)
    client = DropboxClient.new(dropbox_session, ACCESS_TYPE)

    # check for config.yml in users folder
    begin
        tmpcnf = client.get_file("config.yml")
        puts tmpcnf
        cnf = YAML::load(tmpcnf)

        # Optional headers from the user config file
        big_heading = "#" + tm.strftime(cnf['document_heading']) unless cnf['document_heading'] == nil
        daily_heading = "##" + tm.strftime(cnf['daily_heading']) unless cnf['daily_heading'] == nil
        heading = "**" + tm.strftime(cnf['timestamp']) + "** -\t" unless cnf['timestamp'] == nil
    rescue 
        puts "No config file... Good."
    end



    begin
        # try downloading this months file
        oldfile = client.get_file(dropFileName)
        tmpfile.write(oldfile)
        tmpfile.write("  \r\n  \r\n")
    rescue
        # if the file does not exist on dropbox create new tempfile
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
    #puts "uploaded: ", response.inspect

    # cleanup
    tmpfile.close
    tmpfile.unlink

    # display the write page again
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

get '/config' do
    erb :config
end

get '/privacy' do
    erb :privacy
end
