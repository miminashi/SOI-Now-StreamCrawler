require 'mongo_mapper'

#MongoMapper.connection = Mongo::Connection.new('localhost')
#MongoMapper.database = 'streamcrawler'

class Tweet
  include MongoMapper::Document
  key :number, Integer
  key :text,   String
  timestamps!
end

