require 'mysql2'
require 'logger'

require 'active_record'
require 'active_record/base'
require 'active_record/connection_adapters/abstract_mysql_adapter'
require 'active_record/connection_adapters/abstract/connection_pool'
require 'active_support'

module Activerecord
  module Mysql
    module Reconnect

      DEFAULT_EXECUTION_TRIES = 3
      DEFAULT_EXECUTION_RETRY_WAIT = 0.5

      WITHOUT_RETRY_KEY = 'activerecord-mysql-reconnect-without-retry'
      RETRYABLE_TRANSACTION_KEY = 'activerecord-mysql-reconnect-transaction-retry'

      HANDLE_ERROR = [
        ActiveRecord::StatementInvalid,
        Mysql2::Error,
      ]

      HANDLE_ERROR_MESSAGES = [
        'MySQL server has gone away',
        'Server shutdown in progress',
        'closed MySQL connection',
        "Can't connect to MySQL server",
        'Query execution was interrupted',
        'Access denied for user',
        'Lost connection to MySQL server during query',
      ]

      class << self
        def execution_tries
          ActiveRecord::Base.execution_tries || DEFAULT_EXECUTION_TRIES
        end

        def execution_retry_wait
          ActiveRecord::Base.execution_retry_wait || DEFAULT_EXECUTION_RETRY_WAIT
        end

        def should_handle?(e)
          !without_retry? &&
          HANDLE_ERROR.any? {|i| e.kind_of?(i) } &&
          Regexp.union(HANDLE_ERROR_MESSAGES) =~ e.message
        end

        def logger
          if defined?(Rails)
            Rails.logger || ActiveRecord::Base.logger || Logger.new($stderr)
          else
            ActiveRecord::Base.logger || Logger.new($stderr)
          end
        end

        def without_retry
          begin
            Thread.current[WITHOUT_RETRY_KEY] = true
            yield
          ensure
            Thread.current[WITHOUT_RETRY_KEY] = nil
          end
        end

        def without_retry?
          !!Thread.current[WITHOUT_RETRY_KEY]
        end

        def retryable_transaction
          begin
            Thread.current[RETRYABLE_TRANSACTION_KEY] = []

            ActiveRecord::Base.transaction do
              yield
            end
          ensure
            Thread.current[RETRYABLE_TRANSACTION_KEY] = nil
          end
        end

        def retryable_transaction_buffer
          Thread.current[RETRYABLE_TRANSACTION_KEY]
        end
      end # end of class methods

    end # Reconnect
  end # Mysql
end # Activerecord

require 'activerecord/mysql/reconnect/version'
require 'activerecord/mysql/reconnect/base_ext'
require 'activerecord/mysql/reconnect/abstract_mysql_adapter_ext'
require 'activerecord/mysql/reconnect/connection_pool_ext'
