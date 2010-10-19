# -*- encoding: UTF-8 -*-
require 'pp'
require 'rubygems'
require 'mongo_mapper'

#s = Time.now
MongoMapper.connection = Mongo::Connection.new('localhost')
MongoMapper.database = 'test'
#puts "Connect = #{Time.now - s}"

#s = Time.now
=begin
class Tweet
  include MongoMapper::Document
  key :number, Integer
  key :text,   String
  timestamps!
end
=end

class User
  include MongoMapper::EmbeddedDocument
  key :screen_name, String
  key :name, String
end

class Tweet
  include MongoMapper::Document
  key  :t_id,       Integer
  key  :text,       String
  key  :created_at, Data
  many :users
  #key :user_screen_name, String
  #key :user_name, String
end

#puts "class definition = #{Time.now - s}"

=begin
tweet = Tweet.create({
  :number => 0000000001,
  :text   => 'aaaaaaaaaaaaaaaaaaaaaaa'
})
tweet.save
=end

=begin
s = Time.now
1000.times do
  Tweet.count
end
puts "count query = #{Time.now - s}"

s = Time.now
Tweet.all.each do |t|
  p t
end
=end
#puts "request all = #{Time.now - s}"

#=begin
tweet = Tweet.create({
  :t_id => 26464818198350,
  :text => 'qawsedrftgyhujikolps',
  :created_at => Time.now,
})
tweet.users << User.new({
  :screen_name => 'miminashi',
  :name => 'Miminashi'
})
tweet.save
#=end

#pp Tweet.all
#pp Tweet.all(:user_screen_name => 'miminashi')
#Tweet.destroy(3)
#pp Tweet.all
pp Tweet.all(:conditions => {'users.screen_name' => 'miminashi'})

