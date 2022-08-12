# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket::Article
  class SenderType < Gql::Types::BaseObject
    include Gql::Concerns::IsModelObject

    description 'Ticket article senders'

    field :name, String
  end
end
