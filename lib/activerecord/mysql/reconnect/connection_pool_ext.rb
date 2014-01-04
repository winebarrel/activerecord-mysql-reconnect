class ActiveRecord::ConnectionAdapters::ConnectionPool
  def new_connection_with_retry
    Activerecord::Mysql::Reconnect.retryable(
      :proc => proc {
        new_connection_without_retry
      }
    )
  end

  alias_method_chain :new_connection, :retry
end
