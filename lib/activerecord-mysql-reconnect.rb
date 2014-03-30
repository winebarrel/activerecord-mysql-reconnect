ActiveSupport.on_load :active_record do
  require_relative 'activerecord/mysql/reconnect'
end
