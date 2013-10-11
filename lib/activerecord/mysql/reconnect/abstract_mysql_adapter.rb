require 'active_record'
require 'active_record/connection_adapters/abstract_mysql_adapter'
require 'active_support'
require 'retryable'

class ActiveRecord::Base
  class_attribute :execution_tries
  class_attribute :execution_retry_wait
end

class ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter
  MYSQL_SERVER_HAS_GONE_AWAY = 'MySQL server has gone away'
  DEFAULT_EXECUTION_TRIES = 1
  DEFAULT_EXECUTION_RETRY_WAIT = 0.5

  def execute_with_reconnect(sql, name = nil)
    retryable_options = {
      :tries    => (ActiveRecord::Base.execution_tries || DEFAULT_EXECUTION_TRIES),
      :matching => /#{MYSQL_SERVER_HAS_GONE_AWAY}/,
      :sleep    => proc {|n|
        wait = (ActiveRecord::Base.execution_retry_wait || DEFAULT_EXECUTION_RETRY_WAIT) * (n + 1)
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
