module Activerecord::Mysql::Reconnect::ReconnectWithRetry
  def reconnect!
    Activerecord::Mysql::Reconnect.retryable(
      :proc => proc { super },
      :connection => @connection
    )
  end
end

class ActiveRecord::ConnectionAdapters::Mysql2Adapter
  alias_method :reconnect_without_retry!, :reconnect!
  prepend Activerecord::Mysql::Reconnect::ReconnectWithRetry
end
