module Biz
  module CoreExt
    module Date
      def business_day?
        Biz.dates.active?(self)
      end
    end
  end
end
