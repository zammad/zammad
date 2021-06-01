# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  module OTRS
    class CustomerUser
      include Import::Helper
      include Import::OTRS::Helper

      MAPPING = {
        ChangeTime:    :updated_at,
        CreateTime:    :created_at,
        CreateBy:      :created_by_id,
        ChangeBy:      :updated_by_id,
        UserComment:   :note,
        UserEmail:     :email,
        UserFirstname: :firstname,
        UserLastname:  :lastname,
        UserLogin:     :login,
        UserPassword:  :password,
        UserPhone:     :phone,
        UserFax:       :fax,
        UserMobile:    :mobile,
        UserStreet:    :street,
        UserZip:       :zip,
        UserCity:      :city,
        UserCountry:   :country,
      }.freeze

      def initialize(customer)
        import(customer)
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
        @local_customer = ::User.find_by(login: customer[:login])
        return false if !@local_customer

        # do not update user if it is already agent
        return true if @local_customer.role_ids.include?(Role.find_by(name: 'Agent').id)

        # only update roles if different (reduce sql statements)
        if @local_customer.role_ids == customer[:role_ids]
          customer.delete(:role_ids)
        end

        log "update User.find_by(login: #{customer[:login]})"
        @local_customer.update!(customer)
        true
      end

      def create(customer)
        log "add User.find_by(login: #{customer[:login]})"
        @local_customer = ::User.new(customer)
        @local_customer.save
        reset_primary_key_sequence('users')
      end

      def map(customer)
        mapped = map_default(customer)
        mapped[:created_at] ||= DateTime.current
        mapped[:updated_at] ||= DateTime.current
        mapped[:email].downcase!
        mapped[:login].downcase!
        mapped
      end

      def map_default(customer)
        {
          created_by_id:   1,
          updated_by_id:   1,
          active:          active?(customer),
          source:          'OTRS Import',
          organization_id: organization_id(customer),
          role_ids:        role_ids,
        }
          .merge(from_mapping(customer))
      end

      def role_ids
        [
          Role.find_by(name: 'Customer').id
        ]
      end

      def organization_id(customer)
        return if !customer['UserCustomerID']

        organization = Import::OTRS::Customer.by_customer_id(customer['UserCustomerID'])
        return if !organization

        organization.id
      end
    end
  end
end
