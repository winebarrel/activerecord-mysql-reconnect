module Activerecord::Mysql::Reconnect::NewConnectionWithRetry
  def new_connection
    if defined?(db_config)
      Activerecord::Mysql::Reconnect.retryable(
        :proc => proc { super },
        :connection => db_config.configuration_hash
      )
    else
      Activerecord::Mysql::Reconnect.retryable(
        :proc => proc { super },
        :connection => spec.config,
      )
    end
  end
end
class ActiveRecord::ConnectionAdapters::ConnectionPool
  prepend Activerecord::Mysql::Reconnect::NewConnectionWithRetry
end
