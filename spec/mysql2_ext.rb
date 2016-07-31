require 'mysql2'

class Mysql2::Client
  def escape(str); str; end
end
