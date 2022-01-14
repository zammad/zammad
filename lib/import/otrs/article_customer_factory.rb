# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
