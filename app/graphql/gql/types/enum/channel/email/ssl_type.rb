# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class Channel::Email::SSLType < BaseEnum
    description 'Possible values for email SSL/TLS transport security'

    value 'off'
    value 'ssl'
    value 'starttls'
  end
end
