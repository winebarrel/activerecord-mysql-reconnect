require 'active_record'
require 'active_record/connection_adapters/abstract_mysql_adapter'
require 'active_support'

class ActiveRecord::Base
  cattr_accessor :execution_tries
end

class ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter
  MYSQL_SERVER_HAS_GONE_AWAY = 'MySQL server has gone away'
 
  def execute_with_reconnect(sql, name = nil)
    retryable_options = {
      :tries    => (ActiveRecord::Base.execution_tries || 1),
      :matching => /#{MYSQL_SERVER_HAS_GONE_AWAY}/,
      :sleep    => proc {|n|
        wait = 0.5 * (n + 1)
        logger.warn("#{MYSQL_SERVER_HAS_GONE_AWAY}. Trying to reconnect in #{wait} seconds.")
        sleep(wait)
        reconnect!
        0
      }
    }
 
    retryable(retryable_options) do
      execute_without_reconnect(sql, name)
    end
  end
 
  alias_method_chain :execute, :reconnect
end
