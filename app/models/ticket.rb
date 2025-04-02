# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Ticket < ApplicationModel
  include CanBeImported
  include HasActivityStreamLog
  include ChecksClientNotification
  include CanCsvImport
  include ChecksHtmlSanitized
  include ChecksHumanChanges
  include HasHistory
  include HasTags
  include HasSearchIndexBackend
  include HasOnlineNotifications
  include HasLinks
  include HasObjectManagerAttributes
  include HasTaskbars
  include Ticket::CallsStatsTicketReopenLog
  include Ticket::EnqueuesUserTicketCounterJob
  include Ticket::ResetsPendingTimeSeconds
  include Ticket::SetsCloseTime
  include Ticket::SetsOnlineNotificationSeen
  include Ticket::TouchesAssociations
  include Ticket::TriggersSubscriptions
  include Ticket::ChecksReopenAfterCertainTime
  include Ticket::Checklists

  include ::Ticket::Escalation
  include ::Ticket::Subject
  include ::Ticket::Assets
  include ::Ticket::SearchIndex
  include ::Ticket::CanSelector
  include ::Ticket::Search
  include ::Ticket::MergeHistory
  include ::Ticket::PerformChanges

  store :preferences
  after_initialize :check_defaults, if: :new_record?
  before_create  :check_generate, :check_defaults, :check_title, :set_default_state, :set_default_priority
  before_update  :check_defaults, :check_title, :reset_pending_time, :check_owner_active

  # This must be loaded late as it depends on the internal before_create and before_update handlers of ticket.rb.
  include Ticket::SetsLastOwnerUpdateTime

  # workflow checks should run after before_create and before_update callbacks
  # the transaction dispatcher must be run after the workflow checks!
  include ChecksCoreWorkflow
  include HasTransactionDispatcher

  validates :group_id, presence: true

  activity_stream_permission 'ticket.agent'

  core_workflow_screens 'create_middle', 'edit', 'overview_bulk'
  core_workflow_admin_screens 'create_middle', 'edit'

  taskbar_entities 'TicketZoom', 'TicketCreate'
  taskbar_ignore_state_updates_entities 'TicketZoom'

  activity_stream_attributes_ignored :organization_id, # organization_id will change automatically on user update
                                     :create_article_type_id,
                                     :create_article_sender_id,
                                     :article_count,
                                     :first_response_at,
                                     :first_response_escalation_at,
                                     :first_response_in_min,
                                     :first_response_diff_in_min,
                                     :close_at,
                                     :close_escalation_at,
                                     :close_in_min,
                                     :close_diff_in_min,
                                     :update_escalation_at,
                                     :update_in_min,
                                     :update_diff_in_min,
                                     :last_close_at,
                                     :last_contact_at,
                                     :last_contact_agent_at,
                                     :last_contact_customer_at,
                                     :last_owner_update_at,
                                     :preferences

  search_index_attributes_relevant :organization_id,
                                   :group_id,
                                   :state_id,
                                   :priority_id

  history_attributes_ignored :create_article_type_id,
                             :create_article_sender_id,
                             :article_count,
                             :preferences

  history_relation_object 'Ticket::Article', 'Mention', 'Ticket::SharedDraftZoom', 'Checklist', 'Checklist::Item'

  validates :note, length: { maximum: 250 }
  sanitized_html :note

  belongs_to    :group, optional: true
  belongs_to    :organization, optional: true

  has_many      :articles, -> { reorder(:created_at, :id) }, class_name: 'Ticket::Article', after_add: :cache_update, after_remove: :cache_update, dependent: :destroy, inverse_of: :ticket
  has_many      :ticket_time_accounting, class_name: 'Ticket::TimeAccounting', dependent: :destroy, inverse_of: :ticket
  has_many      :mentions,               as: :mentionable, dependent: :destroy
  has_one       :shared_draft,           class_name: 'Ticket::SharedDraftZoom', inverse_of: :ticket, dependent: :destroy
  belongs_to    :state,                  class_name: 'Ticket::State', optional: true
  belongs_to    :priority,               class_name: 'Ticket::Priority', optional: true
  belongs_to    :owner,                  class_name: 'User', optional: true
  belongs_to    :customer,               class_name: 'User', optional: true
  belongs_to    :created_by,             class_name: 'User', optional: true
  belongs_to    :updated_by,             class_name: 'User', optional: true
  belongs_to    :create_article_type,    class_name: 'Ticket::Article::Type', optional: true
  belongs_to    :create_article_sender,  class_name: 'Ticket::Article::Sender', optional: true

  association_attributes_ignored :flags, :mentions

  attr_accessor :callback_loop

=begin

processes tickets which have reached their pending time and sets next state_id

  processed_tickets = Ticket.process_pending

returns

  processed_tickets = [<Ticket>, ...]

=end

  def self.process_pending
    result = []

    # process pending action tickets
    pending_action = Ticket::StateType.find_by(name: 'pending action')
    ticket_states_pending_action = Ticket::State.where(state_type_id: pending_action)
                                                .where.not(next_state_id: nil)
    if ticket_states_pending_action.present?
      next_state_map = {}
      ticket_states_pending_action.each do |state|
        next_state_map[state.id] = state.next_state_id
      end

      where(state_id: next_state_map.keys, pending_time: ..Time.current)
        .find_each(batch_size: 500) do |ticket|
          Transaction.execute do
            ticket.state_id      = next_state_map[ticket.state_id]
            ticket.updated_at    = Time.zone.now
            ticket.updated_by_id = 1
            ticket.save!
          end
          result.push ticket
        end
    end

    # process pending reminder tickets
    pending_reminder = Ticket::StateType.find_by(name: 'pending reminder')
    ticket_states_pending_reminder = Ticket::State.where(state_type_id: pending_reminder)

    if ticket_states_pending_reminder.present?
      reminder_state_map = {}
      ticket_states_pending_reminder.each do |state|
        reminder_state_map[state.id] = state.next_state_id
      end

      where(state_id: reminder_state_map.keys, pending_time: ..Time.current)
        .find_each(batch_size: 500) do |ticket|

          article_id = nil
          article = Ticket::Article.last_customer_agent_article(ticket.id)
          if article
            article_id = article.id
          end

          # send notification
          TransactionJob.perform_now(
            object:     'Ticket',
            type:       'reminder_reached',
            object_id:  ticket.id,
            article_id: article_id,
            user_id:    1,
          )

          result.push ticket
        end
    end

    result
  end

  def auto_assign(user)
    return if !persisted?
    return if Setting.get('ticket_auto_assignment').blank?
    return if owner_id != 1
    return if !TicketPolicy.new(user, self).full?

    user_ids_ignore = Array(Setting.get('ticket_auto_assignment_user_ids_ignore')).map(&:to_i)
    return if user_ids_ignore.include?(user.id)

    ticket_auto_assignment_selector = Setting.get('ticket_auto_assignment_selector')
    return if ticket_auto_assignment_selector.blank?

    condition = ticket_auto_assignment_selector[:condition].merge(
      'ticket.id' => {
        'operator' => 'is',
        'value'    => id,
      }
    )

    ticket_count, = Ticket.selectors(condition, limit: 1, current_user: user, access: 'full')
    return if ticket_count.to_i.zero?

    update!(owner: user)
  end

=begin

processes escalated tickets

  processed_tickets = Ticket.process_escalation

returns

  processed_tickets = [<Ticket>, ...]

=end

  def self.process_escalation
    result = []

    # fetch all escalated and soon to be escalating tickets
    where(escalation_at: ..15.minutes.from_now)
      .find_each(batch_size: 500) do |ticket|
        article_id = nil
        article = Ticket::Article.last_customer_agent_article(ticket.id)
        if article
          article_id = article.id
        end

        # send escalation
        if ticket.escalation_at < Time.zone.now
          TransactionJob.perform_now(
            object:     'Ticket',
            type:       'escalation',
            object_id:  ticket.id,
            article_id: article_id,
            user_id:    1,
          )
          result.push ticket
          next
        end

        # check if warning needs to be sent
        TransactionJob.perform_now(
          object:     'Ticket',
          type:       'escalation_warning',
          object_id:  ticket.id,
          article_id: article_id,
          user_id:    1,
        )
        result.push ticket
      end

    result
  end

=begin

processes tickets which auto unassign time has reached

  processed_tickets = Ticket.process_auto_unassign

returns

  processed_tickets = [<Ticket>, ...]

=end

  def self.process_auto_unassign

    # process pending action tickets
    state_ids = Ticket::State.by_category_ids(:work_on)
    return [] if state_ids.blank?

    result = []
    groups = Group.where(active: true).where('assignment_timeout IS NOT NULL AND groups.assignment_timeout != 0')
    return [] if groups.blank?

    groups.each do |group|
      next if group.assignment_timeout.blank?

      ticket_ids = Ticket.where('state_id IN (?) AND owner_id != 1 AND group_id = ? AND last_owner_update_at IS NOT NULL', state_ids, group.id).limit(600).pluck(:id)
      ticket_ids.each do |ticket_id|
        ticket = Ticket.find_by(id: ticket_id)
        next if !ticket

        minutes_since_last_assignment = Time.zone.now - ticket.last_owner_update_at
        next if (minutes_since_last_assignment / 60) <= group.assignment_timeout

        Transaction.execute do
          ticket.owner_id      = 1
          ticket.updated_at    = Time.zone.now
          ticket.updated_by_id = 1
          ticket.save!
        end
        result.push ticket
      end
    end

    result
  end

=begin

merge tickets

  ticket = Ticket.find(123)
  result = ticket.merge_to(
    ticket_id: 123,
    user_id:   123,
  )

returns

  result = true|false

=end

  def merge_to(data)

    # prevent cross merging tickets
    target_ticket = Ticket.find_by(id: data[:ticket_id])
    raise 'no target ticket given' if !target_ticket
    raise Exceptions::UnprocessableEntity, __('It is not possible to merge into an already merged ticket.') if target_ticket.state.state_type.name == 'merged'

    # check different ticket ids
    raise Exceptions::UnprocessableEntity, __('A ticket cannot be merged into itself.') if id == target_ticket.id

    # update articles
    Transaction.execute context: 'merge' do

      Ticket::Article.where(ticket_id: id).each(&:touch)

      # quiet update of reassign of articles
      Ticket::Article.where(ticket_id: id).update_all(['ticket_id = ?', data[:ticket_id]]) # rubocop:disable Rails/SkipsModelValidations

      # mark target ticket as updated
      # otherwise the "received_merge" history entry
      # will be the same as the last updated_at
      # which might be a long time ago
      target_ticket.updated_at = Time.zone.now

      # add merge event to both ticket's history (Issue #2469 - Add information "Ticket merged" to History)
      target_ticket.history_log(
        'received_merge',
        data[:user_id],
        id_to:   target_ticket.id,
        id_from: id,
      )
      history_log(
        'merged_into',
        data[:user_id],
        id_to:   target_ticket.id,
        id_from: id,
      )

      # create new merge article
      Ticket::Article.create(
        ticket_id:     id,
        type_id:       Ticket::Article::Type.lookup(name: 'note').id,
        sender_id:     Ticket::Article::Sender.lookup(name: 'Agent').id,
        body:          'merged',
        internal:      false,
        created_by_id: data[:user_id],
        updated_by_id: data[:user_id],
      )

      # search for mention duplicates and destroy them before moving mentions
      Mention.duplicates(self, target_ticket).destroy_all
      Mention.where(mentionable: self).update_all(mentionable_id: target_ticket.id) # rubocop:disable Rails/SkipsModelValidations

      # reassign links to the new ticket
      # rubocop:disable Rails/SkipsModelValidations
      ticket_source_id = Link::Object.find_by(name: 'Ticket').id

      # search for all duplicate source and target links and destroy them
      # before link merging
      Link.duplicates(
        object1_id:    ticket_source_id,
        object1_value: id,
        object2_value: data[:ticket_id]
      ).destroy_all
      Link.where(
        link_object_source_id:    ticket_source_id,
        link_object_source_value: id,
      ).update_all(link_object_source_value: data[:ticket_id])
      Link.where(
        link_object_target_id:    ticket_source_id,
        link_object_target_value: id,
      ).update_all(link_object_target_value: data[:ticket_id])
      # rubocop:enable Rails/SkipsModelValidations

      # link tickets
      Link.add(
        link_type:                'parent',
        link_object_source:       'Ticket',
        link_object_source_value: data[:ticket_id],
        link_object_target:       'Ticket',
        link_object_target_value: id
      )

      # external sync references
      ExternalSync.migrate('Ticket', id, target_ticket.id)

      # set state to 'merged'
      state_type = Ticket::StateType.lookup(name: 'merged')
      self.state_id = Ticket::State.lookup(state_type_id: state_type.id).id

      # rest owner
      self.owner_id = 1

      # save ticket
      save!

      # touch new ticket (to broadcast change)
      target_ticket.touch # rubocop:disable Rails/SkipsModelValidations

      EventBuffer.add('transaction', {
                        object:     target_ticket.class.name,
                        type:       'update.received_merge',
                        data:       target_ticket,
                        changes:    {},
                        id:         target_ticket.id,
                        user_id:    UserInfo.current_user_id,
                        created_at: Time.zone.now,
                      })

      EventBuffer.add('transaction', {
                        object:     self.class.name,
                        type:       'update.merged_into',
                        data:       self,
                        changes:    {},
                        id:         id,
                        user_id:    UserInfo.current_user_id,
                        created_at: Time.zone.now,
                      })
    end
    true
  end

=begin

perform active triggers on ticket

  Ticket.perform_triggers(ticket, article, triggers, item, triggers, options)

=end

  def self.perform_triggers(ticket, article, triggers, item, options = {})
    recursive = Setting.get('ticket_trigger_recursive')
    type = options[:type] || item[:type]
    local_options = options.clone
    local_options[:type] = type
    local_options[:reset_user_id] = true
    local_options[:disable] = ['Transaction::Notification']
    local_options[:trigger_ids] ||= {}
    local_options[:trigger_ids][ticket.id.to_s] ||= []
    local_options[:loop_count] ||= 0
    local_options[:loop_count] += 1

    ticket_trigger_recursive_max_loop = Setting.get('ticket_trigger_recursive_max_loop')&.to_i || 10
    if local_options[:loop_count] > ticket_trigger_recursive_max_loop
      message = "Stopped perform_triggers for this object (Ticket/#{ticket.id}), because loop count was #{local_options[:loop_count]}!"
      logger.info { message }
      return [false, message]
    end

    return [true, __('No triggers active')] if triggers.blank?

    # check if notification should be send because of customer emails
    send_notification = true
    if local_options[:send_notification] == false
      send_notification = false
    elsif item[:article_id]
      article = Ticket::Article.lookup(id: item[:article_id])
      if article&.preferences && article.preferences['send-auto-response'] == false
        send_notification = false
      end
    end

    Transaction.execute(local_options) do
      triggers.each do |trigger|
        logger.debug { "Probe trigger (#{trigger.name}/#{trigger.id}) for this object (Ticket:#{ticket.id}/Loop:#{local_options[:loop_count]})" }

        user_id = ticket.updated_by_id
        if article
          user_id = article.updated_by_id
        end

        user = User.lookup(id: user_id)

        # verify is condition is matching
        ticket_count, tickets = Ticket.selectors(
          trigger.condition,
          limit:            1,
          execution_time:   true,
          current_user:     user,
          access:           'ignore',
          ticket_action:    type,
          ticket_id:        ticket.id,
          article_id:       article&.id,
          changes:          item[:changes],
          changes_required: trigger.condition_changes_required?
        )

        next if ticket_count.blank?
        next if ticket_count.zero?
        next if tickets.take.id != ticket.id

        return [true, message] if recursive == false && local_options[:loop_count] > 1

        if article && send_notification == false && trigger.perform['notification.email'] && trigger.perform['notification.email']['recipient']
          recipient = trigger.perform['notification.email']['recipient']
          local_options[:send_notification] = false
          if recipient.include?('ticket_customer') || recipient.include?('article_last_sender')
            logger.info { "Skip trigger (#{trigger.name}/#{trigger.id}) because sender do not want to get auto responder for object (Ticket/#{ticket.id}/Article/#{article.id})" }
            next
          end
        end

        if local_options[:trigger_ids][ticket.id.to_s].include?(trigger.id)
          logger.info { "Skip trigger (#{trigger.name}/#{trigger.id}) because was already executed for this object (Ticket:#{ticket.id}/Loop:#{local_options[:loop_count]})" }
          next
        end
        local_options[:trigger_ids][ticket.id.to_s].push trigger.id
        logger.info { "Execute trigger (#{trigger.name}/#{trigger.id}) for this object (Ticket:#{ticket.id}/Loop:#{local_options[:loop_count]})" }

        ticket.perform_changes(trigger, 'trigger', item, user_id, activator_type: type)

        if recursive == true
          TransactionDispatcher.commit(local_options)
        end
      end
    end
    [true, ticket, local_options]
  end

=begin

get all email references headers of a ticket, to exclude some, parse it as array into method

  references = ticket.get_references

result

  ['message-id-1234', 'message-id-5678']

ignore references header(s)

  references = ticket.get_references(['message-id-5678'])

result

  ['message-id-1234']

=end

  # limited by 32kb (https://github.com/zammad/zammad/issues/5334)
  # https://learn.microsoft.com/en-us/office365/servicedescriptions/exchange-online-service-description/exchange-online-limits
  def get_references(ignore = [], max_length: 30_000)
    references = []
    counter    = 0
    Ticket::Article.select('in_reply_to, message_id').where(ticket_id: id).reorder(id: :desc).each do |article|
      new_references = []
      if article.message_id.present?
        new_references.push article.message_id
      end
      if article.in_reply_to.present?
        new_references.push article.in_reply_to
      end
      new_references -= ignore

      counter += new_references.join.length
      break if counter > max_length

      references.unshift(*new_references)
    end
    references
  end

  # Get whichever #last_contact_* was later
  # This is not identical to #last_contact_at
  # It returns time to last original (versus follow up) contact
  # @return [Time, nil]
  def last_original_update_at
    [last_contact_agent_at, last_contact_customer_at].compact.max
  end

  # true if conversation did happen and agent responded
  # false if customer is waiting for response or agent reached out and customer did not respond yet
  # @return [Bool]
  def agent_responded?
    return false if last_contact_customer_at.blank?
    return false if last_contact_agent_at.blank?

    last_contact_customer_at < last_contact_agent_at
  end

=begin

Get the color of the state the current ticket is in

  ticket.current_state_color

returns a hex color code

=end
  def current_state_color
    return '#f35912' if escalation_at && escalation_at < Time.zone.now

    case state.state_type.name
    when 'new', 'open'
      return '#faab00'
    when 'closed'
      return '#38ad69'
    when 'pending reminder'
      return '#faab00' if pending_time && pending_time < Time.zone.now
    end

    '#000000'
  end

  def mention_user_ids
    mentions.pluck(:user_id)
  end

  private

  def check_generate
    return true if number

    self.number = Ticket::Number.generate
    true
  end

  def check_title
    return true if !title

    title.gsub!(%r{\s|\t|\r}, ' ')
    true
  end

  def check_defaults
    check_default_owner
    check_default_organization
    true
  end

  def check_default_owner
    return if !has_attribute?(:owner_id)
    return if owner_id || owner

    self.owner_id = 1
  end

  def check_default_organization
    return if !has_attribute?(:organization_id)
    return if !customer_id

    customer = User.find_by(id: customer_id)
    return if !customer
    return if organization_id.present? && customer.organization_id?(organization_id)
    return if organization.present? && customer.organization_id?(organization.id)

    self.organization_id = customer.organization_id
  end

  def reset_pending_time

    # ignore if no state has changed
    return true if !changes_to_save['state_id']

    # ignore if new state is blank and
    # let handle ActiveRecord the error
    return if state_id.blank?

    # check if new state isn't pending*
    current_state      = Ticket::State.lookup(id: state_id)
    current_state_type = Ticket::StateType.lookup(id: current_state.state_type_id)

    # in case, set pending_time to nil
    return true if current_state_type.name.match?(%r{^pending}i)

    self.pending_time = nil
    true
  end

  def set_default_state
    return true if state_id

    default_ticket_state = Ticket::State.find_by(default_create: true)
    return true if !default_ticket_state

    self.state_id = default_ticket_state.id
    true
  end

  def set_default_priority
    return true if priority_id

    default_ticket_priority = Ticket::Priority.find_by(default_create: true)
    return true if !default_ticket_priority

    self.priority_id = default_ticket_priority.id
    true
  end

  def check_owner_active
    return true if Setting.get('import_mode')

    # only change the owner for non closed Tickets for historical/reporting reasons
    return true if state.present? && Ticket::StateType.lookup(id: state.state_type_id)&.name == 'closed'

    # return when ticket is unassigned
    return true if owner_id.blank?
    return true if owner_id == 1

    # return if owner is active, is agent and has access to group of ticket
    return true if owner.active? && owner.permissions?('ticket.agent') && owner.group_access?(group_id, 'full')

    # else set the owner of the ticket to the default user as unassigned
    self.owner_id = 1
    true
  end
end
