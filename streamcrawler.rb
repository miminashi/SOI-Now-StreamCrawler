# -*- encoding: UTF-8 -*-
require 'pp'
require 'time'
require 'rubygems'
require 'sinatra'
require 'erb'
require 'em-http'
require 'json'
require 'mongo_mapper'
#require 'tweet.rb'
require 'settings.rb'

# Time zone converter
# from http://d.hatena.ne.jp/tonkoh/20080901/1220287952
#
class Time
  def convert_zone(to_zone)
    original_zone = ENV['TZ']
    utc_time = dup.gmtime
    ENV['TZ'] = to_zone
    to_zone_time = utc_time.localtime
    ENV['TZ'] = original_zone
    return to_zone_time
  end
end

MongoMapper.connection = Mongo::Connection.new(MONGO_SERVER)
MongoMapper.database = MONGO_DATABASE

class User
  include MongoMapper::EmbeddedDocument
  key :screen_name,       String
  key :name,              String
  key :profile_image_url, String
end

class Hashtag
  include MongoMapper::EmbeddedDocument
  key :hashtag, String
end

class Tweet
  include MongoMapper::Document
  key  :t_id,       Integer
  key  :text,       String
  key  :created_at, Data
  many :users
  many :hashtags
end

class Place
  include MongoMapper::Document
  key :name, String
  key :lat,  Float
  key :log,  Float
end

class Activity
  include MongoMapper::Document
  key :title,       String
  key :hashtag,     String
  key :description, String
end

helpers do
  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="authenticate required")
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [ADMIN_USER, ADMIN_PASS]
  end
end


get '/' do
  redirect '/activities'
end

get '/activities' do
  @activities = Activity.all
  erb :activities
end

get '/activities/new' do
  protected!
  erb :activities_new
end

post '/activities/create' do
  protected!
  redirect '/activities/new' if (params[:title] =~ /^$/ or params[:hashtag] =~ /^$|\s+|\#|\-/)
  Activity.create({:title => params[:title], :hashtag => params[:hashtag], :description => params[:description]})
  $http.close_connection
  crawler
  redirect '/'
end

get '/activities/:id' do
  @a = Activity.find(params[:id])
  if @a == nil
    erb :activities_not_found
  else
    p @a.hashtag
    @c = Tweet.count('hashtags.hashtag' => @a.hashtag)
    #@tweets = Tweet.all('hashtags.hashtag' => @a.hashtag, :limit => 10, :sort => ['t_id', 'desc'])
    @tweets = Tweet.all('hashtags.hashtag' => @a.hashtag, :limit => 10, :order => 't_id desc')
    erb :activities_show
  end
end

get '/tweets' do
  erb :tweets
end

get '/reboot_crawler' do
  protected!
  $http.close_connection
  crawler
  redirect '/'
end

get '/emtest' do
  #p Activity.all.map {|a| '#' + a.hashtag }.join(',')
  #$http.close_connection
  #crawler
end

def handle_tweet(t)
  return unless t['text']
  tweet = Tweet.create({
    :t_id => t['id'],
    :text => t['text'],
    :created_at => Time.parse(t['created_at']).utc,
  })
  tweet.users << User.new({
    :screen_name => t['user']['screen_name'],
    :name => t['user']['name'],
    :profile_image_url => t['user']['profile_image_url']
  })
  t['entities']['hashtags'].each do |h|
    tweet.hashtags << Hashtag.new({
      :hashtag => h['text']
    })
  end
  tweet.save
end

def crawler
  hashtags = Activity.all.map {|a| '#' + a.hashtag }.join(',')
  $http = EM::HttpRequest.new(STREAMING_URL).post(:head => {'Authorization' => [ID, PASSWD]}, :timeout => 0, :query => {'track' => hashtags})
  puts "connected"
  buffer = ""
  $http.stream do |chunk|
    buffer += chunk
    while line = buffer.slice!(/.+\r?\n/)
      begin
        handle_tweet(JSON.parse(line))
      rescue => e
        p e
      end
    end
  end
end

EM.schedule do
  crawler
  #$http = EM::HttpRequest.new(STREAMING_URL).post(:head => {'Authorization' => [ID, PASSWD]}, :timeout => 0, :query => {'track' => HASHTAGS})
  #buffer = ""
  #$http.stream do |chunk|
  #  buffer += chunk
  #  while line = buffer.slice!(/.+\r?\n/)
  #    begin
  #      handle_tweet(JSON.parse(line))
  #    rescue => e
  #      p e
  #    end
  #  end
  #end
end

