# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Chat::Session
  module Search
    extend ActiveSupport::Concern

    include CanSearch

    # methods defined here are going to extend the class, not the instance of it
    class_methods do

=begin

search organizations preferences

  result = Chat::Session.search_preferences(user_model)

returns if user has permissions to search

  result = {
    prio: 1000,
    direct_search_index: true
  }

returns if user has no permissions to search

  result = false

=end

      def search_preferences(current_user)
        return false if Setting.get('chat') != true || !current_user.permissions?('chat.agent')

        {
          prio:                900,
          direct_search_index: true,
        }
      end
    end
  end
end
