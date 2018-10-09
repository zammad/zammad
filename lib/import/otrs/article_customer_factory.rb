module Import
  module OTRS
    module ArticleCustomerFactory
      extend Import::Factory

      def skip?(record, *_args)
        return true if record['SenderType'] != 'customer'
        return true if record['CreatedBy'].to_i != 1
        return true if record['From'].blank?

        false
      end
    end
  end
end
