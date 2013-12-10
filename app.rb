require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'tempfile'
require 'yaml'
require 'dropbox_sdk'
require 'active_support/core_ext/integer/inflections'
require 'active_support/time'
require 'tzinfo'

#YAML::ENGINE.yamler= 'syck'
config = YAML::load_file('config.yml')

APP_KEY = config['key']
APP_SECRET = config['secret']
URL = config['url']
ACCESS_TYPE = :app_folder

DEFAULT_TIMEZONE = "America/New_York"

enable :sessions

get '/' do
    @loggedin = (session[:dropbox] != nil)
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

        client = DropboxClient.new(dropbox_session, ACCESS_TYPE)
        list = client.metadata('/')
        @files = list['contents']

        @loggedin = (session[:dropbox] != nil)
        erb :write
    rescue
        puts '######################'
        puts $!, $@
        redirect '/login'
    end
end

get '/read/:file' do

    # make sure the user authorized with Drobox
    redirect '/login' unless session[:dropbox] 
    
    # get DropboxSession out of Sinatra session store again
    dropbox_session = DropboxSession::deserialize(session[:dropbox])

    # make sure it still has access token
    redirect '/login' unless dropbox_session.authorized?

    client = DropboxClient.new(dropbox_session, ACCESS_TYPE)
    temp = client.get_file(params[:file])

    @loggedin = (session[:dropbox] != nil)
    erb :read, :locals => { :content => markdown(temp) }
end

post '/write' do

    # make sure the user authorized with Drobox
    redirect '/login' unless session[:dropbox] 
    
    # get DropboxSession out of Sinatra session store again
    dropbox_session = DropboxSession::deserialize(session[:dropbox])

    # make sure it still has access token
    redirect '/login' unless dropbox_session.authorized?

    entry = params[:entry]

    # if empty string was submitted, do nothing
    redirect '/write' if entry.empty?
   
    client = DropboxClient.new(dropbox_session, ACCESS_TYPE)

    # check for config.yml in users folder
    begin
        tmpcnf = client.get_file("config.yml")
        puts tmpcnf
        cnf = YAML::load(tmpcnf)
        
    rescue 
        puts "No config file... Good."
    end

    if cnf != nil
        # try setting user defined time zone. If the string is wrong
        # the zone will default to nil
        (timeZone = TZInfo::Timezone.get(cnf['timezone'])) rescue nil
    end

    # Set timezone to EST if it is not set
    timeZone = TZInfo::Timezone.get(DEFAULT_TIMEZONE) unless timeZone != nil
    
    tm = timeZone.utc_to_local(Time.now.utc)

    # Figure out name for current file
    # Default format is YYYY-MM-Monthname.markdown
    dropFileName = tm.strftime("%Y-%m.%B") + ".markdown"
    tmpfile = Tempfile.new(dropFileName)

    # Figure out the Headings
    
    # Goes at the top of a new document
    big_heading = "#" + tm.strftime("%B %Y")
    
    # Day of the week - only included once per day
    daily_heading = "##" + tm.strftime("%A") + " the " + tm.day.ordinalize
    
    # Time-stamp for each entry
    heading = "**" + tm.strftime("%l:%M%P").strip + "** -\t"
    
    if cnf != nil
        big_heading = "#" + tm.strftime(cnf['document_heading']) unless cnf['document_heading'] == nil
        daily_heading = "##" + tm.strftime(cnf['daily_heading']) unless cnf['daily_heading'] == nil
        heading = "**" + tm.strftime(cnf['timestamp']).strip + "** -\t" unless cnf['timestamp'] == nil
    end

    begin
        # try downloading this months file
        oldfile = client.get_file(dropFileName)
        tmpfile.write(oldfile)
        tmpfile.write("  \r\n  \r\n")
    rescue DropboxError => e
        # if the file does not exist on dropbox create new tempfile
        puts "Error downloading file from Dropbox."
        puts e.message
        
        # We want to bug out if it is a different error message
        if e.message == 'File not found' || e.message == 'File has been deleted'
            newfile = true
            tmpfile.write(big_heading+"  \r\n  \r\n")
        end
    end 
    
    # include daily heading if it is not in already
    tmpfile.write(daily_heading + "  \r\n  \r\n") unless ( oldfile != nil && oldfile.include?(daily_heading) )

    # append the entry to the end of the file
    tmpfile.write(heading)
    tmpfile.write(entry)
    tmpfile.close

    # Drobpbox upload (only if old file exists, or new file was legally created)
    if oldfile || newfile
        tmpfile.open
        response = client.put_file("/"+dropFileName, tmpfile, true)
        #puts "uploaded: ", response.inspect
    end

    # cleanup
    tmpfile.close
    tmpfile.unlink

    # display the write page again
    client = DropboxClient.new(dropbox_session, ACCESS_TYPE)
    list = client.metadata('/')
    @files = list['contents']

    @saved = 1
    @loggedin = (session[:dropbox] != nil)
    erb :write
end

get '/about' do
    @loggedin = (session[:dropbox] != nil)
    erb :about
end

get '/contact' do
    @loggedin = (session[:dropbox] != nil)
    erb :contact
end

get '/config' do
    @loggedin = (session[:dropbox] != nil)
    erb :config
end

get '/privacy' do
    @loggedin = (session[:dropbox] != nil)
    erb :privacy
end
