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

    def retryable_transaction
      begin
        Thread.current[ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter::RETRYABLE_TRANSACTION_KEY] = []

        ActiveRecord::Base.transaction do
          yield
        end
      ensure
        Thread.current[ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter::RETRYABLE_TRANSACTION_KEY] = nil
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
  RETRYABLE_TRANSACTION_KEY = 'activerecord-mysql-reconnect-transaction-retry'

  def execute_with_reconnect(sql, name = nil)
    retryable(sql, name) do |sql_names|
      retval = nil

      sql_names.each do |s, n|
        retval = execute_without_reconnect(s, n)
      end

      add_sql_to_transaction(sql, name)
      retval
    end
  end

  alias_method_chain :execute, :reconnect

  private

  def retryable(sql, name, &block)
    tries = ActiveRecord::Base.execution_tries || DEFAULT_EXECUTION_TRIES
    logger = ActiveRecord::Base.logger || Logger.new($stderr)
    block_with_reconnect = nil
    retval = nil
    sql_names = [[sql, name]]

    retryable_loop(tries) do |n|
      begin
        retval = (block_with_reconnect || block).call(sql_names)
        break
      rescue => e
        if not without_retry? and (tries.zero? or n < tries) and e.message =~ Regexp.union(ERROR_MESSAGES)
          unless block_with_reconnect
            block_with_reconnect = proc {|i| reconnect! ; block.call(i) }
          end

          sql_names = merge_transaction(sql, name)
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

  def add_sql_to_transaction(sql, name)
    if (buf = Thread.current[RETRYABLE_TRANSACTION_KEY])
      buf << [sql, name]
    end
  end

  def merge_transaction(sql, name)
    sql_name = [sql, name]

    if (buf = Thread.current[RETRYABLE_TRANSACTION_KEY])
      buf + [sql_name]
    else
      [sql_name]
    end
  end
end
