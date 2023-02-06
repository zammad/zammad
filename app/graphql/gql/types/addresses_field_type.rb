# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class AddressesFieldType < Gql::Types::BaseObject
    description 'A field which may contain one or more email or other addresses.'

    field :raw, String, null: false, description: 'Unparsed content of the addresses field.'
    field :parsed, [Gql::Types::Email::AddressType], description: 'If email addresses were found and parseable, this will hold the parsed result.'

    def raw
      object
    end

    def parsed
      Mail::AddressList
        .new(object)
        .addresses
        .map { |elem| { name: elem.name, email_address: elem.address } }
    rescue Mail::Field::ParseError
      nil
    end
  end
end
