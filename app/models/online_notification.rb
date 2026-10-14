# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class OnlineNotification < ApplicationModel
  include HasDefaultModelUserRelations

  include OnlineNotification::Assets
  include OnlineNotification::TriggersSubscriptions
  include OnlineNotification::SendsWebPush

  belongs_to :user, optional: true
  # rubocop:disable Rails/InverseOf
  belongs_to :object, class_name: 'ObjectLookup', foreign_key: 'object_lookup_id', optional: true
  belongs_to :type,   class_name: 'TypeLookup',   foreign_key: 'type_lookup_id', optional: true
  # rubocop:enable Rails/InverseOf

  after_create    :notify_clients_after_change
  after_update    :notify_clients_after_change
  after_destroy   :notify_clients_after_change

=begin

add a new online notification for this user

  OnlineNotification.add(
    type:          'Assigned to you',
    object:        'Ticket',
    o_id:          ticket.id,
    seen:          false,
    user_id:       2,
    created_by_id: 1,
    updated_by_id: 1,
    created_at:    Time.zone.now,
    updated_at:    Time.zone.now,
  )

=end

  def related_object
    ObjectLookup
      .by_id(object_lookup_id)
      &.safe_constantize
      &.find_by(id: o_id)
  end

  # The tag of a web push about this notification. Notifications of one ticket
  #   share it, so a device keeps one push per ticket.
  def push_tag
    self.class.push_tags([self])[id]
  end

  # Push tags by notification id, for a relation or loaded notifications,
  #   resolved with a fixed number of queries whatever their number.
  def self.push_tags(notifications)
    ticket_lookup  = ObjectLookup.by_name('Ticket')
    article_lookup = ObjectLookup.by_name('Ticket::Article')
    rows           = notifications.pluck(:id, :object_lookup_id, :o_id)

    article_ids     = rows.filter_map { |_, lookup, o_id| o_id if lookup == article_lookup }
    article_tickets = Ticket::Article.where(id: article_ids).pluck(:id, :ticket_id).to_h
    ticket_ids      = rows.filter_map { |_, lookup, o_id| o_id if lookup == ticket_lookup }
    existing        = Ticket.where(id: ticket_ids + article_tickets.values).pluck(:id).to_set

    rows.to_h do |id, lookup, o_id|
      ticket_id = case lookup
                  when ticket_lookup  then o_id
                  when article_lookup then article_tickets[o_id]
                  end

      [id, existing.include?(ticket_id) ? "ticket-#{ticket_id}" : "online-notification-#{id}"]
    end
  end

  def self.add(data)
    if data[:kind].present?
      add_standalone(data)
    end

    # lookups
    if data[:type]
      type_id = TypeLookup.by_name(data[:type])
    end
    if data[:object]
      object_id = ObjectLookup.by_name(data[:object])
    end

    # check if object for online notification exists
    exists_by_object_and_id?(data[:object], data[:o_id])

    record = {
      o_id:             data[:o_id],
      object_lookup_id: object_id,
      type_lookup_id:   type_id,
      seen:             data[:seen],
      meta:             data[:meta] || {},
      user_id:          data[:user_id],
      created_by_id:    data[:created_by_id],
      updated_by_id:    data[:updated_by_id] || data[:created_by_id],
      created_at:       data[:created_at] || Time.zone.now,
      updated_at:       data[:updated_at] || Time.zone.now,
    }

    OnlineNotification.create!(record)
  end

  def self.add_standalone(data)
    standalone_notification = OnlineNotificationStandalone.create!(data.slice(:data, :kind))
    data.except!(:data, :kind)

    data[:type]   = standalone_notification.kind
    data[:object] = OnlineNotificationStandalone.name
    data[:o_id]   = standalone_notification.id
  end

=begin

remove whole online notifications of an object

  OnlineNotification.remove('Ticket', 123)

=end

  def self.remove(object_name, o_id)
    object_id = ObjectLookup.by_name(object_name)
    OnlineNotification.where(
      object_lookup_id: object_id,
      o_id:             o_id,
    ).destroy_all
  end

=begin

remove whole online notifications of an object by type

  OnlineNotification.remove_by_type('Ticket', 123, type, user)

=end

  def self.remove_by_type(object_name, o_id, type_name, user)
    object_id = ObjectLookup.by_name(object_name)
    type_id = TypeLookup.by_name(type_name)
    OnlineNotification.where(
      object_lookup_id: object_id,
      type_lookup_id:   type_id,
      o_id:             o_id,
      user_id:          user.id,
    ).destroy_all
  end

=begin

return online notifications of an user, limited to those whose related object the user may read

@param user [User] to get notifications of
@param limit [Integer] of notifications to get
@param access [String] group access the user needs on a related ticket: 'full', 'read' or 'create';
  'ignore' skips the related object check altogether
@param ids [Array<Integer>] to restrict the list to, e.g. to check a single notification

@example

  notifications = OnlineNotification.list(user, limit: 123, access: 'full')

=end

  def self.list(user, limit: 200, access: 'read', ids: nil)
    relation = OnlineNotification
      .where(user_id: user.id)
      .reorder(created_at: :desc, id: :desc)
      .limit(limit)
    relation = relation.where(id: ids) if ids

    return relation if access == 'ignore'

    relation.merge(related_object_accessible(relation, user, access))
  end

  def self.related_object_accessible(relation, user, access)
    ticket_object_id     = ObjectLookup.by_name('Ticket')
    article_object_id    = ObjectLookup.by_name('Ticket::Article')
    standalone_object_id = ObjectLookup.by_name('OnlineNotificationStandalone')

    # Only the newest page of candidates is authorized: an older one belongs to the page only when
    #   fewer than a page of newer notifications are accessible, which is not worth checking all.
    policy_candidates = relation.where.not(object_lookup_id: [ticket_object_id, article_object_id, standalone_object_id])

    # Each check is correlated on the notification row: an uncorrelated subselect in an OR branch
    #   is not planned as a join, so it would enumerate every readable ticket or article per call.
    readable_tickets = Ticket.where(group_id: user.group_ids_access(access))
    readable_ticket  = readable_tickets.where('tickets.id = online_notifications.o_id')
    readable_article = Ticket::Article.joins(:ticket).merge(readable_tickets).where('ticket_articles.id = online_notifications.o_id')
    own_standalone   = own_standalone_ids(user).where('online_notification_standalones.id = online_notifications.o_id')

    where(object_lookup_id: ticket_object_id).where(readable_ticket.arel.exists)
      .or(where(object_lookup_id: article_object_id).where(readable_article.arel.exists))
      .or(where(object_lookup_id: standalone_object_id).where(own_standalone.arel.exists))
      .or(where(id: policy_accessible_ids(user, policy_candidates)))
  end
  private_class_method :related_object_accessible

  # A standalone record has no owner column: it is created together with the notification of the
  #   user it is for, so it stops counting as theirs once another user's notification points at it.
  def self.own_standalone_ids(user)
    foreign_ids = where(object_lookup_id: ObjectLookup.by_name('OnlineNotificationStandalone'))
      .where.not(user_id: user.id)
      .select(:o_id)

    OnlineNotificationStandalone.where.not(id: foreign_ids).select(:id)
  end

  # Object types without a query of their own (e.g. a knowledge base answer) are authorized one
  #   record at a time, with the related records loaded in one query per class beforehand. The
  #   policy checks themselves still query per record, e.g. for the effective knowledge base
  #   permission: the page of candidates bounds that cost, the preload does not remove it.
  def self.policy_accessible_ids(user, candidates)
    candidates      = candidates.to_a
    related_objects = related_objects_of(candidates)

    candidates.filter_map do |notification|
      notification.id if OnlineNotificationPolicy.new(user, notification).related_accessible?(related_objects[notification.id])
    end
  end
  private_class_method :policy_accessible_ids

  # What the policy of a related object reads before deciding, loaded together with the object.
  RELATED_OBJECT_PRELOADS = {
    'KnowledgeBase::Answer::Translation' => { answer: { category: :knowledge_base } },
  }.freeze

  def self.related_objects_of(notifications)
    notifications
      .group_by { |notification| ObjectLookup.by_id(notification.object_lookup_id)&.safe_constantize }
      .each_with_object({}) do |(klass, grouped), result|
        records = klass ? klass.where(id: grouped.map(&:o_id)).preload(RELATED_OBJECT_PRELOADS[klass.name]).index_by(&:id) : {}

        grouped.each { |notification| result[notification.id] = records[notification.o_id] }
      end
  end
  private_class_method :related_objects_of

=begin

return all online notifications of an object

  notifications = OnlineNotification.list_by_object('Ticket', 123)

=end

  def self.list_by_object(object_name, o_id)
    object_id = ObjectLookup.by_name(object_name)

    OnlineNotification
      .where(
        object_lookup_id: object_id,
        o_id:             o_id,
      )
      .reorder(created_at: :desc)
      .limit(10_000)
  end

=begin

cleanup old online notifications

  OnlineNotification.cleanup

with dedicated times

  max_age = Time.zone.now - 9.months
  max_own_seen = Time.zone.now - 10.minutes
  max_auto_seen = Time.zone.now - 8.hours

  OnlineNotification.cleanup(max_age, max_own_seen, max_auto_seen)

=end

  def self.cleanup(max_age = 9.months.ago, max_own_seen = 10.minutes.ago, max_auto_seen = 8.hours.ago)
    affected_user_ids = []

    where(created_at: ...max_age)
      .tap { |relation| affected_user_ids |= relation.distinct.pluck(:user_id) }
      .delete_all

    where(seen: true)
      .where('(user_id = updated_by_id AND updated_at < :max_own_seen) OR (user_id != updated_by_id AND updated_at < :max_auto_seen)',
             max_own_seen:, max_auto_seen:)
      .tap { |relation| affected_user_ids |= relation.distinct.pluck(:user_id) }
      .delete_all

    cleanup_notify_agents(affected_user_ids)

    true
  end

  def self.cleanup_notify_agents(user_ids)
    return if user_ids.blank?

    User
      .with_permissions('ticket.agent')
      .where(id: user_ids)
      .each do |user|
        Sessions.send_to(
          user.id,
          {
            event: 'OnlineNotification::changed',
            data:  {}
          }
        )
        trigger_subscriptions(user)
      end
  end

=begin

check if online notification should be shown in general as already seen with current state

  ticket = Ticket.find(1)
  seen = OnlineNotification.seen_state?(ticket, user_id_check)

returns

  result = true # or false

=end

  def self.seen_state?(ticket, user_id_check = nil)
    state      = Ticket::State.lookup(id: ticket.state_id)
    state_type = Ticket::StateType.lookup(id: state.state_type_id)

    # always to set unseen for ticket owner and users which did not the update
    return false if seen_state_not_merged_owner?(state_type, ticket, user_id_check)

    # set all to seen if pending action state is a closed or merged state
    if state_type.name == 'pending action' && state.next_state_id
      state      = Ticket::State.lookup(id: state.next_state_id)
      state_type = Ticket::StateType.lookup(id: state.state_type_id)
    end

    # set all to seen if new state is pending reminder state
    if state_type.name == 'pending reminder'
      return seen_state_pending_reminder?(ticket, user_id_check)
    end

    # set all to seen if new state is a closed or merged state
    return true if %w[closed merged].include? state_type.name

    false
  end

  def self.seen_state_pending_reminder?(ticket, user_id_check)
    return true if !user_id_check

    return false if ticket.owner_id == 1
    return false if ticket.updated_by_id != ticket.owner_id && user_id_check == ticket.owner_id

    true
  end
  private_class_method :seen_state_pending_reminder?

  def self.seen_state_not_merged_owner?(state_type, ticket, user_id_check)
    return false if state_type.name == 'merged'
    return false if !user_id_check

    user_id_check == ticket.owner_id && user_id_check != ticket.updated_by_id
  end
  private_class_method :seen_state_not_merged_owner?

  # Marks all notifications for object/user pair as seen.
  # Also makes sure to trigger subscription only once.
  def self.mark_as_seen!(object, user)
    notifications = list_by_object(object.class.name, object.id).where(seen: false, user:)

    without_callback(:commit, :after, :trigger_subscriptions) do
      notifications.each { it.update!(seen: true) }
    end

    return if notifications.empty?

    ApplicationModel.current_transaction.after_commit do
      trigger_subscriptions(user)
    end
  end

  def mark_as_seen!
    return if seen

    update!(seen: true)

    return if !user

    ApplicationModel.current_transaction.after_commit do
      self.class.trigger_subscriptions(user)
    end
  end

  private

  def notify_clients_after_change
    Sessions.send_to(
      user_id,
      {
        event: 'OnlineNotification::changed',
        data:  {}
      }
    )
  end
end
