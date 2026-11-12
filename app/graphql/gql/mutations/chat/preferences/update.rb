# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Chat::Preferences::Update < BaseMutation
    description 'Update the chat preferences of the current agent'

    argument :preferences, Gql::Types::Input::Chat::PreferencesInputType, description: 'The chat preferences to change'

    field :preferences, Gql::Types::Chat::PreferencesType, description: 'The chat preferences as stored'

    requires_permission 'chat.agent'
    requires_enabled_setting 'chat'

    def resolve(preferences:)
      changes = preferences.to_h

      changes[:topics] = changes[:topics]&.map do |entry|
        { topic: Gql::ZammadSchema.verified_object_from_id(entry[:topic_id], type: ::Chat), active: entry[:active], phrases: entry[:phrases] }
      end

      { preferences: Service::Chat::Preferences::Update.with_current_user(context.current_user).execute(**changes) }
    rescue Exceptions::UnprocessableContent => e
      error_response({ message: e.message })
    end
  end
end
