# -*- encoding: UTF-8 -*-
require 'rubygems'
require 'mongoid'

s = Time.now
class Person
  include Mongoid::Document
  field :first_name
end
puts "class definition = #{Time.now - s}"

