# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket::Article
  class MediaErrorStateType < Gql::Types::BaseObject
    description 'Ticket article media error information, e.g. for WhatsApp Business'

    field :error, Boolean

    def error
      @object['media_error']
    end
  end
end
