# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Import
  module OTRS
    module ArticleCustomerFactory
      extend Import::Factory

      def skip?(record, *_args)
        return true if record['SenderType'] != 'customer'
        return true if create_by_id(record) != 1
        return true if record['From'].blank?

        false
      end

      private

      def create_by_id(record)
        return record['CreatedBy'].to_i if record['CreatedBy'].present?

        record['CreateBy'].to_i
      end
    end
  end
end
