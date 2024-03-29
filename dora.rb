ENV['RACK_ENV'] ||= 'development'

require 'rubygems'
require 'sinatra/base'
require 'json'

ID = ((ENV["VCAP_APPLICATION"] && JSON.parse(ENV["VCAP_APPLICATION"])["instance_id"]) || SecureRandom.uuid).freeze

require "instances"
require "stress_testers"
require "log_utils"
require 'bundler'
Bundler.require :default, ENV['RACK_ENV'].to_sym

$stdout.sync = true
$stderr.sync = true

class Dora < Sinatra::Base
  use Instances
  use StressTesters
  use LogUtils

  get '/' do
# "Hi I'm Dora!"
'<html><body><img width="100%" src="http://www.chillestmonkey.com/img/monkey.gif" /></body></html>'
  end

  get '/find/:filename' do
    `find / -name #{params[:filename]}`
  end

  get '/sigterm' do
    "Available sigterms #{`man -k signal | grep list`}"
  end

  get '/delay/:seconds' do
    sleep params[:seconds].to_i
    "YAWN! Slept so well for #{params[:seconds].to_i} seconds"
  end

  get '/sigterm/:signal' do
    pid = Process.pid
    signal = params[:signal]
    puts "Killing process #{pid} with signal #{signal}"
    Process.kill(signal, pid)
  end

  get '/logspew/:bytes' do
    system "cat /dev/urandom | head -c #{params[:bytes].to_i}"
    "Just wrote #{params[:bytes]} random bytes to the log"
  end

  get '/echo/:destination/:output' do
    redirect =
        case params[:destination]
          when "stdout"
            ""
          when "stderr"
            " 1>&2"
          else
            " > #{params[:destination]}"
        end

    system "echo '#{params[:output]}'#{redirect}"

    "Printed '#{params[:output]}' to #{params[:destination]}!"
  end

  get '/env/:name' do
    ENV[params[:name]]
  end

  get '/env' do
    ENV.to_hash.to_s
  end

  run! if app_file == $0
end
