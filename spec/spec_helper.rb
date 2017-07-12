require 'mysql2_ext'
require 'mysql_helper'
require 'activerecord/mysql/reconnect'
require 'employee_model'

module SpecHelper
  def thread_start
    thread_running = false

    th = Thread.start {
      thread_running = true
      yield
      thread_running = false
    }

    60.times do
      Thread.pass
      break if thread_running
      sleep 1
    end

    unless thread_running
      raise 'thread is not running'
    end

    th
  end

  def myisam?
    ENV['ACTIVERECORD_MYSQL_RECONNECT_ENGINE'] =~ /MyISAM/i
  end
end

include SpecHelper

RSpec.configure do |config|
  config.before(:all) do
    MysqlServer.stop
  end

  config.after(:all) do
    MysqlServer.stop
  end

  config.before(:each) do |context|
    MysqlServer.start
    MysqlServer.reset
    ActiveRecord::Base.clear_all_connections!
  end
end
