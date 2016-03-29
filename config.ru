require "rubygems"
require "sinatra"
require 'sinatra/config_file'

require File.expand_path '../deploy_listener.rb', __FILE__

run DeployListener
