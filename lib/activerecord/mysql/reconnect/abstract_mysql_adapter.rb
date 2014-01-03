require 'active_record'
require 'active_record/connection_adapters/abstract_mysql_adapter'
require 'active_support'
require 'logger'

class ActiveRecord::Base
  class_attribute :execution_tries
  class_attribute :execution_retry_wait
end

class ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter
  ERROR_MESSAGES = [
    'MySQL server has gone away',
    'Server shutdown in progress',
    'closed MySQL connection',
    "Can't connect to MySQL server",
  ]

  DEFAULT_EXECUTION_TRIES = 3
  DEFAULT_EXECUTION_RETRY_WAIT = 0.5

  def execute_with_reconnect(sql, name = nil)
    retryable do
      execute_without_reconnect(sql, name)
    end
  end

  alias_method_chain :execute, :reconnect

  private

  def retryable(&block)
    tries = ActiveRecord::Base.execution_tries || DEFAULT_EXECUTION_TRIES
    logger = ActiveRecord::Base.logger || Logger.new($stderr)
    block_with_reconnect = nil
    retval = nil

    tries.times do |n|
      begin
        retval = (block_with_reconnect || block).call
        break
      rescue => e
        if (n + 1) < tries and e.message =~ Regexp.union(ERROR_MESSAGES)
          block_with_reconnect = proc { reconnect! ; block.call } unless block_with_reconnect
          wait = (ActiveRecord::Base.execution_retry_wait || DEFAULT_EXECUTION_RETRY_WAIT) * (n + 1)
          logger.warn("MySQL server has gone away. Trying to reconnect in #{wait} seconds.")
          sleep(wait)
          next
        else
          raise e
        end
      end
    end

    return retval
  end
end
