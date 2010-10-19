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

#MongoMapper.connection = Mongo::Connection.new('localhost')
#MongoMapper.database = 'streamcrawler'
MongoMapper.connection = Mongo::Connection.new(MONGO_SERVER)
MongoMapper.database = MONGO_DATABASE

=begin
class Tweet
  include MongoMapper::Document
  key :id,   Integer
  key :text, String
  key :created_at, Data
  key :user_screen_name, String
  key :user_name, String
  timestamps!
end
=end

class User
  include MongoMapper::EmbeddedDocument
  key :screen_name, String
  key :name,        String
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

get '/' do
  redirect '/activities'
end

get '/activities' do
  @activities = Activity.all
  erb :activities
end

get '/activities/new' do
  erb :activities_new
end

post '/activities/create' do
  redirect '/activities/new' if (params[:title] =~ /^$/ or params[:hashtag] =~ /^$|\s+|\#|\-/)
  Activity.create({:title => params[:title], :hashtag => params[:hashtag], :description => params[:description]})
  redirect '/'
end

get '/activities/:id' do
  #pp Hashtag.methods
  #pp BSON::ObjectId.new(params[:id])
  @a = Activity.find(params[:id])
  if @a == nil
    erb :activities_not_found
  else
    p @a.hashtag
    #@c = Tweet.count(:contidions => {'hashtags.hashtag' => @a.hashtag})
    @c = Tweet.count('hashtags.hashtag' => @a.hashtag)
    #@t = Tweet.all(:conditions => {'hashtags.hashtag' => @a.hashtag})
    @t = Tweet.all('hashtags.hashtag' => @a.hashtag)
    pp @c
    pp @t
    erb :activities_show
  end
end

get '/tweets' do
  #content_type 'text/html', :charset => 'utf-8'
  #TWEETS.map {|tweet| "<p><b>#{tweet['user']['screen_name']}</b>: #{tweet['text']}</p>" }.join
  erb :tweets
end

=begin
class RingBuffer < Array
  def initialize(size)
    @max = size
    super(0)
  end

  def push(object)
    shift if size == @max
    super
  end
end
=end

#TWEETS = RingBuffer.new(10)
#STREAMING_URL = 'http://stream.twitter.com/1/statuses/filter.json'
#STREAMING_URL = 'http://stream.twitter.com/1/statuses/sample.json'

def handle_tweet(t)
  return unless t['text']
  tweet = Tweet.create({
    :t_id => t['id'],
    :text => t['text'],
    :created_at => Time.parse(t['created_at']).utc,
  })
  tweet.users << User.new({
    :screen_name => t['user']['screen_name'],
    :name => t['user']['name']
  })
  t['entities']['hashtags'].each do |h|
    tweet.hashtags << Hashtag.new({
      :hashtag => h['text']
    })
  end
  tweet.save
end


EM.schedule do
  http = EM::HttpRequest.new(STREAMING_URL).post(:head => {'Authorization' => [ID, PASSWD]}, :timeout => 0, :query => {'track' => HASHTAGS})
  #http = EM::HttpRequest.new(STREAMING_URL).get(:head => {'Authorization' => ['botmmns01', 'botmmns']})
  buffer = ""
  http.stream do |chunk|
    buffer += chunk
    #p buffer
    while line = buffer.slice!(/.+\r?\n/)
      #pp line
      begin
        handle_tweet(JSON.parse(line))
      rescue => e
        p e
      end
    end
  end
end

