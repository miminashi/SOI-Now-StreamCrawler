#!/bin/sh

term -t ruby streamcrawler.rb
term -t
open 'http://localhost:4567/'
sudo mongod

