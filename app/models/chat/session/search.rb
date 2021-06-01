# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Chat::Session
  module Search
    extend ActiveSupport::Concern

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

=begin

search organizations

  result = Chat::Session.search(
    current_user: User.find(123),
    query: 'search something',
    limit: 15,
    offset: 100,
  )

returns

  result = [organization_model1, organization_model2]

=end

      def search(params)

        # get params
        query = params[:query]
        limit = params[:limit] || 10
        offset = params[:offset] || 0
        current_user = params[:current_user]

        # enable search only for agents and admins
        return [] if !search_preferences(current_user)

        # try search index backend
        if SearchIndexBackend.enabled?
          items = SearchIndexBackend.search(query, 'Chat::Session', limit: limit, from: offset)
          chat_sessions = []
          items.each do |item|
            chat_session = Chat::Session.lookup(id: item[:id])
            next if !chat_session

            chat_sessions.push chat_session
          end
          return chat_sessions
        end

        # fallback do sql query
        # - stip out * we already search for *query* -
        query.delete! '*'
        Chat::Session.where(
          'name LIKE ?', "%#{query}%"
        ).order('name').offset(offset).limit(limit).to_a

      end
    end
  end
end
