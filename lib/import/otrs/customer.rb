# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  module OTRS
    class Customer
      include Import::Helper
      include Import::OTRS::Helper

      MAPPING = {
        ChangeTime:             :updated_at,
        CreateTime:             :created_at,
        CreateBy:               :created_by_id,
        ChangeBy:               :updated_by_id,
        CustomerCompanyName:    :name,
        CustomerCompanyComment: :note,
      }.freeze

      def initialize(customer)
        import(customer)
      end

      def self.by_customer_id(customer_id)
        organizations = Import::OTRS::Requester.load('Customer')

        result = nil
        organizations.each do |organization|
          next if customer_id != organization['CustomerID']

          result = Organization.find_by(name: organization['CustomerCompanyName'])
          break
        end
        result
      end

      private

      def import(customer)
        create_or_update(map(customer))
      end

      def create_or_update(customer)
        return if updated?(customer)

        create(customer)
      end

      def updated?(customer)
        @local_customer = Organization.find_by(name: customer[:name])
        return false if !@local_customer

        log "update Organization.find_by(name: #{customer[:name]})"
        @local_customer.update!(customer)
        true
      end

      def create(customer)
        log "add Organization.find_by(name: #{customer[:name]})"
        @local_customer = Organization.create(customer)
        reset_primary_key_sequence('organizations')
      end

      def map(customer)
        {
          created_by_id: 1,
          updated_by_id: 1,
          active:        active?(customer),
        }
          .merge(from_mapping(customer))
      end
    end
  end
end
