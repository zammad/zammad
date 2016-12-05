module Import
  module OTRS
    module ArticleCustomerFactory
      extend Import::Factory

      def skip?(record)
        return true if record['sender'] != 'customer'
        return true if record['created_by_id'].to_i != 1
        return true if record['from'].empty?
        false
      end
    end
  end
end
