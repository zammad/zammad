# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::Link::List < Service::BaseWithCurrentUser

  # Create a list of object related references filtered by target type
  # (Ticket, KnowledgeBase::Answer::Translation).
  #
  # Any reference to a target object that is not accessible by the current user
  # is filtered out.
  def execute(object:, target_type:)
    links = ::Link.list(
      link_object:       object.class.name,
      link_object_value: object.id
    ).select { |link| link['link_object'] == target_type }

    links.filter_map do |link|
      type = link['link_type']
      target_class = link['link_object'].constantize
      target = target_class.find(link['link_object_value'])

      # We prefer to do it here instead of passing the user to the Link model.
      next if !Pundit.policy(current_user, target).show?

      {
        item: target,
        type: type
      }
    end.uniq
  end
end
