module Activerecord::Mysql::Reconnect::NewConnectionWithRetry
  def new_connection
    Activerecord::Mysql::Reconnect.retryable(
      :proc => proc { super },
      :connection => spec.config,
    )
  end
end
class ActiveRecord::ConnectionAdapters::ConnectionPool
  prepend Activerecord::Mysql::Reconnect::NewConnectionWithRetry
end
