module Biz
  module CoreExt
  end
end

require 'biz/core_ext/date'
require 'biz/core_ext/integer'
require 'biz/core_ext/time'

Date.class_eval    do include Biz::CoreExt::Date    end
Integer.class_eval do include Biz::CoreExt::Integer end
Time.class_eval    do include Biz::CoreExt::Time    end
