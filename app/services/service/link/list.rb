# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Link::List < Service::Base
  requires_current_user!

  # What the targets' policies read, loaded with the targets instead of once per target.
  POLICY_PRELOADS = {
    'Ticket'                             => %i[group organization],
    'KnowledgeBase::Answer::Translation' => [{ answer: { category: :knowledge_base } }],
  }.freeze

  attr_reader :object, :target_type

  def initialize(object:, target_type:)
    @object = object
    @target_type = target_type
  end

  # Create a list of object related references filtered by target type
  # (Ticket, KnowledgeBase::Answer::Translation).
  #
  # Any reference to a target object that is not accessible by the current user
  # is filtered out, as is one whose target no longer exists.
  def execute
    links = ::Link.list(
      link_object:       object.class.name,
      link_object_value: object.id
    ).select { |link| link['link_object'] == target_type }

    targets = load_targets(links)

    links.filter_map do |link|
      target = targets[link['link_object_value']]

      # We prefer to do it here instead of passing the user to the Link model.
      next if target.nil? || !Pundit.policy(current_user, target).show?

      {
        item: target,
        type: link['link_type']
      }
    end.uniq
  end

  private

  # All targets in one query, so that the number of links does not drive the number of queries.
  def load_targets(links)
    return {} if links.empty?

    links.first['link_object'].constantize
      .includes(POLICY_PRELOADS.fetch(target_type, []))
      .where(id: links.pluck('link_object_value'))
      .index_by(&:id)
  end
end
