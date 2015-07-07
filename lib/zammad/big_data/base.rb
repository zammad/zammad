module Zammad
  module BigData
    class Base
      # rubocop:disable Style/ClassVars
      @@api_host = 'https://bigdata.zammad.com'
      @@open_timeout = 4
      @@read_timeout = 6
    end
  end
end
