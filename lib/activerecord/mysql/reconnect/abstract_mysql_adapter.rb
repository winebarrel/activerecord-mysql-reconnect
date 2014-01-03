require 'active_record'
require 'active_record/connection_adapters/abstract_mysql_adapter'
require 'active_support'
require 'logger'

class ActiveRecord::Base
  class_attribute :execution_tries
  class_attribute :execution_retry_wait

  class << self
    def without_retry
      begin
        Thread.current[ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter::WITHOUT_RETRY_KEY] = true
        yield
      ensure
        Thread.current[ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter::WITHOUT_RETRY_KEY] = nil
      end
    end
  end
end

class ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter
  DEFAULT_EXECUTION_TRIES = 3
  DEFAULT_EXECUTION_RETRY_WAIT = 0.5

  ERROR_MESSAGES = [
    'MySQL server has gone away',
    'Server shutdown in progress',
    'closed MySQL connection',
    "Can't connect to MySQL server",
    'Query execution was interrupted',
  ]

  WITHOUT_RETRY_KEY = 'activerecord-mysql-reconnect-without-retry'
  TRANSACTION_RETRY_KEY = 'activerecord-mysql-reconnect-transaction-retry'

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

    retryable_loop(tries) do |n|
      begin
        retval = (block_with_reconnect || block).call
        break
      rescue => e
        if not without_retry? and (tries.zero? or n < tries) and e.message =~ Regexp.union(ERROR_MESSAGES)
          unless block_with_reconnect
            block_with_reconnect = proc { reconnect! ; block.call }
          end

          wait = (ActiveRecord::Base.execution_retry_wait || DEFAULT_EXECUTION_RETRY_WAIT) * n
          logger.warn("MySQL server has gone away. Trying to reconnect in #{wait} seconds. (cause: #{e} [#{e.class}])")
          sleep(wait)

          next
        else
          raise e
        end
      end
    end

    return retval
  end

  def retryable_loop(n)
    if n.zero?
      loop { n += 1 ; yield(n) }
    else
      n.times {|i| yield(i + 1) }
    end
  end

  def without_retry?
    !!Thread.current[WITHOUT_RETRY_KEY]
  end
end
