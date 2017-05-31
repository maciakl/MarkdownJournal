require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'tempfile'
require 'yaml'
require 'dropbox_api'
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

def authenticator
    # Create dropbox session object and serialize it to the Sinatra session
    authenticator = DropboxApi::Authenticator.new(APP_KEY, APP_SECRET)
end

enable :sessions

get '/' do
    @loggedin = (session[:dropbox] != nil)
    erb :index
end

get '/login' do
    session[:dropbox] = 'init'
    # redirect user to Dropbox auth page
    redirect authenticator.authorize_url :redirect_uri => URL #= dropbox_session.get_authorize_url(URL)
end

get '/auth' do

    redirect 'login' unless session[:dropbox] == 'init'

    auth = authenticator.get_token(params['code'], :redirect_uri => URL)
    token = auth.token

    session[:dropbox] = token
    redirect '/write'
end

get '/logout' do
    # destroy session array
    session[:dropbox] = nil
    redirect 'https://www.dropbox.com/logout'
end

get '/write' do

    redirect '/login' unless session[:dropbox] != nil
    redirect '/auth' if session[:dropbox] == 'init' 

    begin

        token = session[:dropbox]
        
        client = DropboxApi::Client.new(token)
        list = client.list_folder "" #get_metadata('/')
        @files = list.entries #list['contents']

        @loggedin = (session[:dropbox] != nil)
        erb :write
    rescue
        puts '######################'
        puts '######################'
        puts '######################'
        puts '######################'
        puts $!, $@
        redirect '/login'
    end
end

get '/read/:file' do

    cache_control :no_cache, :no_store

    # make sure the user authorized with Drobox
    redirect '/login' unless session[:dropbox] 
    
    # get Dropbox token out of session store
    token  = session[:dropbox]
    redirect '/login' if token == 'init'

    client = DropboxApi::Client.new(token)

    temp = ""
    client.download("/"+params[:file]) do |chunk|
      temp += chunk
    end

    @loggedin = (session[:dropbox] != nil)
    erb :read, :locals => { :content => markdown(temp) }
end

post '/write' do

    cache_control :no_cache, :no_store

    # make sure the user authorized with Drobox
    redirect '/login' unless session[:dropbox] 
    
    # get Dropbox token from session
    token = session[:dropbox]
    redirect '/login' if token == 'init'

    entry = params[:entry]

    # if empty string was submitted, do nothing
    redirect '/write' if entry.empty?
   
    client = DropboxApi::Client.new(token)

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

    # buffer for the contents of the post
    buffer = ""

    begin
        # try downloading this months file and add it to buffer
        client.download("/"+dropFileName) do |chunk|
          buffer += chunk
        end
        buffer += "  \r\n  \r\n"
    rescue Exception => e
        # if the file does not exist on dropbox create new tempfile
        puts "Error downloading file from Dropbox."
        puts e.message
        
        # We want to bug out if it is a different error message
        if e.message.include?("not_found")
            buffer += big_heading + "  \r\n  \r\n"
        end
    end 
    
    # include daily heading if it is not in already
    buffer += daily_heading + "  \r\n  \r\n" unless ( buffer != "" && buffer.include?(daily_heading) )

    # append the heading and entry to the end of the buffer
    buffer += heading
    buffer += entry

    # Drobpbox upload the contents of the buffer if not empty
    if buffer != ""
        response = client.upload("/"+dropFileName, buffer, :mode => :overwrite )
        #puts "uploaded: ", response.inspect
    end

    # cleanup
    buffer = nil

    # display the write page again
    list = client.list_folder ""
    @files = list.entries

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

get '/news' do
    @loggedin = (session[:dropbox] != nil)
    erb :news
end
