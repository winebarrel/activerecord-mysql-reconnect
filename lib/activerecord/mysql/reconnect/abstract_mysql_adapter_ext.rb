module ExecuteWithReconnect
  def execute(sql, name = nil)
    retryable(sql, name) do |sql_names|
      retval = nil

      sql_names.each do |s, n|
        retval = super(s, n)
      end

      retval
    end
  end
end

class ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter
  prepend ExecuteWithReconnect

  private

  def retryable(sql, name, &block)
    block_with_reconnect = nil
    sql_names = [[sql, name]]

    Activerecord::Mysql::Reconnect.retryable(
      :proc => proc {
        (block_with_reconnect || block).call(sql_names)
      },
      :on_error => proc {
        unless block_with_reconnect
          block_with_reconnect = proc do |i|
            reconnect_without_retry!
            block.call(i)
          end
        end
      },
      :sql => sql,
      :retry_mode => Activerecord::Mysql::Reconnect.retry_mode,
      :connection => @connection
    )
  end
end
