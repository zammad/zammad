# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module HasTaskbars
  extend ActiveSupport::Concern

  included do
    before_destroy :destroy_taskbars
  end

  class_methods do
    # Defines the entities which are available for the taskbar.
    def taskbar_entities(*entities)
      @taskbar_entities ||= entities
    end

    def taskbar_ignore_state_updates_entities(*entities)
      @taskbar_ignore_state_updates_entities ||= entities
    end

    # Defines the Pundit query the entity of a taskbar entry is authorized with,
    # for the entities that need more than the default :show? (see
    # Taskbar.entity_pundit_method).
    def taskbar_entity_pundit_methods(methods = {})
      @taskbar_entity_pundit_methods ||= methods
    end

    # Declares that the taskbar entries of this model are related to each other -
    # their owners see one another as live users - and the Pundit query that
    # decides who belongs in that list.
    #
    # Not every taskbar model wants this: a user or organization tab shows no
    # live users, and collecting them would put the other viewers into a
    # preferences hash nothing reads.
    #
    # A model that opts in needs a Gql::Subscriptions::<Model>::LiveUserUpdates
    # to push the list with (see Taskbar::TriggersSubscriptions), with the
    # permission *that* model's editors hold.
    def taskbar_live_user_pundit_method(method = nil)
      @taskbar_live_user_pundit_method ||= method
    end
  end

=begin

destroy all taskbars for the class object id

  model = Model.find(123)
  model.destroy

=end

  def destroy_taskbars
    key = Taskbar.entity_key(self)

    # Tabs of a *part* of the record carry a qualifier behind its id (see
    # Taskbar.entity_key), and they belong to the record just as much: the edit
    # tabs of an answer must not outlive it, one per locale though they are.
    Taskbar
      .where(key: key)
      .or(Taskbar.where('taskbars.key LIKE ?', "#{SqlHelper.quote_like(key)}-%"))
      .destroy_all
  end

end
