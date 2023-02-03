# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class AutocompleteSearch::Recipient < AutocompleteSearch::User

    description 'Search for recipients'

    argument :input, Gql::Types::Input::AutocompleteSearch::RecipientInputType, required: true, description: 'The input object for the recipient autocomplete search'

    def post_process(results, input:)
      results.flat_map do |user|
        case input[:contact]
        when 'phone'
          user_phone_contacts(user)
        else
          user_email_contact(user)
        end
      end.map { |user| coerce_to_result(user) }
    end

    def coerce_to_result(contact)
      {
        value:   contact[:contact],
        label:   contact[:contact],
        heading: contact[:name],
      }
    end

    private

    def user_phone_contacts(user)
      contacts = []

      if user.mobile.present?
        contacts.push({
                        name:    user.fullname,
                        contact: user.mobile,
                      })
      end

      if user.phone.present?
        contacts.push({
                        name:    user.fullname,
                        contact: user.phone,
                      })
      end

      contacts
    end

    def user_email_contact(user)
      return [] if user.email.empty?

      {
        name:    user.fullname,
        contact: user.email,
      }
    end
  end
end
