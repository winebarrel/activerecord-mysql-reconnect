module ActiveRecord
  module ConnectionAdapters
    class ConnectionPool

      def new_connection_with_reconnect
        Activerecord::Mysql::Reconnect.retryable(
          :proc => proc {
            new_connection_without_reconnect
          }
        )
      end

      alias_method_chain :new_connection, :reconnect
    end
  end
end
