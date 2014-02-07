require 'sinatra'
require "sinatra/reloader" if development?
require 'active_record'
require 'digest/sha1'
require 'pry'
require 'uri'
require 'open-uri'
# require 'nokogiri'



###########################################################
# Configuration
###########################################################

set :public_folder, File.dirname(__FILE__) + '/public'
set :sessions => true

register do
  def loggin_in? (type)
    condition do
        unless User.find_by_password_hash(session[:id])
            redirect "/login"
        end
    end
  end
end

configure :development, :production do
    ActiveRecord::Base.establish_connection(
       :adapter => 'sqlite3',
       :database =>  'db/dev.sqlite3.db'
     )
end

before do
end
# Handle potential connection pool timeout issues
after do
    ActiveRecord::Base.connection.close
end

# turn off root element rendering in JSON
ActiveRecord::Base.include_root_in_json = false

###########################################################
# Models
###########################################################
# Models to Access the database through ActiveRecord.
# Define associations here if need be
# http://guides.rubyonrails.org/association_basics.html

class Link < ActiveRecord::Base
    attr_accessor :updated_at

    has_many :clicks

    validates :url, presence: true

    before_save do |record|
        record.code = Digest::SHA1.hexdigest(url)[0,5]
    end
end

class Click < ActiveRecord::Base
    belongs_to :link, counter_cache: :visits, touch: true
end

class User < ActiveRecord::Base
end

###########################################################
# Routes
###########################################################

get '/login' do
    erb :login
end

post '/login' do
    username = params[:username]
    password = params[:password]
    user = User.find_by_username(username)

    if user
        password_salt = user.password_salt
        password_hash = user.password_hash
    end

    if(password_hash && password_hash == hashingFunc(password, password_salt))
        session[:id] = password_hash
        redirect to '/'
    else
        puts 'wrong login info'
        redirect '/login'
    end
end

post '/createAccount' do
    password_salt = 'abc'
    password_hash = hashingFunc(params[:password], password_salt)
    User.create(username: params[:username], password_hash: password_hash, password_salt: password_salt, hashId: 'a')
    session[:id] = password_hash
    # session
    redirect to '/'
end

get '/', :loggin_in? => :user do
    puts session[:id].inspect
    # puts request.cookies
    erb :index
end

get '/links', :loggin_in? => :user do
    links = Link.order("visits DESC")
    links.map { |link|
        link.as_json.merge(base_url: request.base_url)
    }.to_json
end

post '/links', :loggin_in? => :user do
    data = JSON.parse request.body.read
    if /^http:\/\//.match data['url']
      data = data['url']
    else
      data = 'http://' + data['url']
    end
    uri = URI(data)
    puts uri
    raise Sinatra::NotFound unless uri.absolute?
    link = Link.find_by_url(uri.to_s) ||
           Link.create( url: uri.to_s, title: get_url_title(uri) )
    link.as_json.merge(base_url: request.base_url).to_json
end

get '/clicks/:code' do
    link = Link.find_by_code(params[:code])
    clicks = Click.where(link_id: link.id)
    clicks.to_json
end

get '/details/:code' do
    erb :index
    # erb :index
end

get '/:url', :loggin_in? => :user do
    link = Link.find_by_code params[:url]
    raise Sinatra::NotFound if link.nil?
    link.update_attribute(:lastclicked, Time.new.to_i)
    link.clicks.create!
    redirect link.url
end

get '/title/:code', :loggin_in? => :user do
    link = Link.find_by_code params[:code]
    link.title
end


###########################################################
# Utility
###########################################################

def read_url_head url
    head = ""
    url.open do |u|
        begin
            line = u.gets
            next  if line.nil?
            head += line
            break if line =~ /<\/head>/
        end until u.eof?
    end
    head + "</html>"
end

def get_url_title url
    # Nokogiri::HTML.parse( read_url_head url ).title
    result = read_url_head(url).match(/<title>(.*)<\/title>/)
    result.nil? ? "" : result[1]
end

def hashingFunc password, salt
    password + salt
end
