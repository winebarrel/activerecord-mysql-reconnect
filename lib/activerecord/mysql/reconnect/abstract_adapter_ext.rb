class ActiveRecord::ConnectionAdapters::AbstractAdapter
  def verify_with_reconnect!(*ignored)
    Activerecord::Mysql::Reconnect.retryable(
      :proc => proc {
        verify_without_reconnect!(*ignored)
      }
    )
  end

  alias_method_chain :verify!, :reconnect
end
