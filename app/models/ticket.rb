# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Ticket < ApplicationModel
  include CanBeImported
  include HasActivityStreamLog
  include ChecksClientNotification
  include ChecksLatestChangeObserved
  include CanCsvImport
  include ChecksHtmlSanitized
  include HasHistory
  include HasTags
  include HasSearchIndexBackend
  include HasOnlineNotifications
  include HasKarmaActivityLog
  include HasLinks
  include HasObjectManagerAttributesValidation
  include HasTaskbars
  include Ticket::CallsStatsTicketReopenLog
  include Ticket::EnqueuesUserTicketCounterJob
  include Ticket::ResetsPendingTimeSeconds
  include Ticket::SetsCloseTime
  include Ticket::SetsOnlineNotificationSeen
  include Ticket::TouchesAssociations

  include ::Ticket::Escalation
  include ::Ticket::Subject
  include ::Ticket::Assets
  include ::Ticket::SearchIndex
  include ::Ticket::Search
  include ::Ticket::MergeHistory

  store          :preferences
  before_create  :check_generate, :check_defaults, :check_title, :set_default_state, :set_default_priority
  before_update  :check_defaults, :check_title, :reset_pending_time, :check_owner_active

  # This must be loaded late as it depends on the internal before_create and before_update handlers of ticket.rb.
  include Ticket::SetsLastOwnerUpdateTime

  include HasTransactionDispatcher

  validates :group_id, presence: true

  activity_stream_permission 'ticket.agent'

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
                                     :last_contact_at,
                                     :last_contact_agent_at,
                                     :last_contact_customer_at,
                                     :last_owner_update_at,
                                     :preferences

  history_attributes_ignored :create_article_type_id,
                             :create_article_sender_id,
                             :article_count,
                             :preferences

  history_relation_object 'Ticket::Article', 'Mention'

  sanitized_html :note

  belongs_to    :group, optional: true
  belongs_to    :organization, optional: true
  has_many      :articles,               class_name: 'Ticket::Article', after_add: :cache_update, after_remove: :cache_update, dependent: :destroy, inverse_of: :ticket
  has_many      :ticket_time_accounting, class_name: 'Ticket::TimeAccounting', dependent: :destroy, inverse_of: :ticket
  has_many      :flags,                  class_name: 'Ticket::Flag', dependent: :destroy
  has_many      :mentions,               as: :mentionable, dependent: :destroy
  belongs_to    :state,                  class_name: 'Ticket::State', optional: true
  belongs_to    :priority,               class_name: 'Ticket::Priority', optional: true
  belongs_to    :owner,                  class_name: 'User', optional: true
  belongs_to    :customer,               class_name: 'User', optional: true
  belongs_to    :created_by,             class_name: 'User', optional: true
  belongs_to    :updated_by,             class_name: 'User', optional: true
  belongs_to    :create_article_type,    class_name: 'Ticket::Article::Type', optional: true
  belongs_to    :create_article_sender,  class_name: 'Ticket::Article::Sender', optional: true

  association_attributes_ignored :flags, :mentions

  self.inheritance_column = nil

  attr_accessor :callback_loop

=begin

get user access conditions

  conditions = Ticket.access_condition( User.find(1) , 'full')

returns

  result = [user1, user2, ...]

=end

  def self.access_condition(user, access)
    sql  = []
    bind = []

    if user.permissions?('ticket.agent')
      sql.push('group_id IN (?)')
      bind.push(user.group_ids_access(access))
    end

    if user.permissions?('ticket.customer')
      if !user.organization || ( !user.organization.shared || user.organization.shared == false )
        sql.push('tickets.customer_id = ?')
        bind.push(user.id)
      else
        sql.push('(tickets.customer_id = ? OR tickets.organization_id = ?)')
        bind.push(user.id)
        bind.push(user.organization.id)
      end
    end

    return if sql.blank?

    [ sql.join(' OR ') ].concat(bind)
  end

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

      tickets = where(state_id: next_state_map.keys)
                .where('pending_time <= ?', Time.zone.now)

      tickets.find_each(batch_size: 500) do |ticket|
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

      tickets = where(state_id: reminder_state_map.keys)
                .where('pending_time <= ?', Time.zone.now)

      tickets.find_each(batch_size: 500) do |ticket|

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

=begin

processes escalated tickets

  processed_tickets = Ticket.process_escalation

returns

  processed_tickets = [<Ticket>, ...]

=end

  def self.process_escalation
    result = []

    # fetch all escalated and soon to be escalating tickets
    where('escalation_at <= ?', Time.zone.now + 15.minutes).find_each(batch_size: 500) do |ticket|

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

      # check if warning need to be sent
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
    state_ids = Ticket::State.by_category(:work_on).pluck(:id)
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
    raise Exceptions::UnprocessableEntity, 'ticket already merged, no merge into merged ticket possible' if target_ticket.state.state_type.name == 'merged'

    # check different ticket ids
    raise Exceptions::UnprocessableEntity, 'Can\'t merge ticket with it self!' if id == target_ticket.id

    # update articles
    Transaction.execute do

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
      self.state_id = Ticket::State.lookup(name: 'merged').id

      # rest owner
      self.owner_id = 1

      # save ticket
      save!

      # touch new ticket (to broadcast change)
      target_ticket.touch # rubocop:disable Rails/SkipsModelValidations
    end
    true
  end

=begin

check if online notification should be shown in general as already seen with current state

  ticket = Ticket.find(1)
  seen = ticket.online_notification_seen_state(user_id_check)

returns

  result = true # or false

=end

  def online_notification_seen_state(user_id_check = nil)
    state      = Ticket::State.lookup(id: state_id)
    state_type = Ticket::StateType.lookup(id: state.state_type_id)

    # always to set unseen for ticket owner and users which did not the update
    return false if state_type.name != 'merged' && user_id_check && user_id_check == owner_id && user_id_check != updated_by_id

    # set all to seen if pending action state is a closed or merged state
    if state_type.name == 'pending action' && state.next_state_id
      state      = Ticket::State.lookup(id: state.next_state_id)
      state_type = Ticket::StateType.lookup(id: state.state_type_id)
    end

    # set all to seen if new state is pending reminder state
    if state_type.name == 'pending reminder'
      if user_id_check
        return false if owner_id == 1
        return false if updated_by_id != owner_id && user_id_check == owner_id

        return true
      end
      return true
    end

    # set all to seen if new state is a closed or merged state
    return true if state_type.name == 'closed'
    return true if state_type.name == 'merged'

    false
  end

=begin

get count of tickets and tickets which match on selector

@param  [Hash] selectors hash with conditions
@oparam [Hash] options

@option options [String]  :access can be 'full', 'read', 'create' or 'ignore' (ignore means a selector over all tickets), defaults to 'full'
@option options [Integer] :limit of tickets to return
@option options [User]    :user is a current user
@option options [Integer] :execution_time is a current user

@return [Integer, [<Ticket>]]

@example
  ticket_count, tickets = Ticket.selectors(params[:condition], limit: limit, current_user: current_user, access: 'full')

  ticket_count # count of found tickets
  tickets      # tickets

=end

  def self.selectors(selectors, options)
    limit = options[:limit] || 10
    current_user = options[:current_user]
    access = options[:access] || 'full'
    raise 'no selectors given' if !selectors

    query, bind_params, tables = selector2sql(selectors, current_user: current_user, execution_time: options[:execution_time])
    return [] if !query

    ActiveRecord::Base.transaction(requires_new: true) do

      if !current_user || access == 'ignore'
        ticket_count = Ticket.distinct.where(query, *bind_params).joins(tables).count
        tickets = Ticket.distinct.where(query, *bind_params).joins(tables).limit(limit)
        return [ticket_count, tickets]
      end

      access_condition = Ticket.access_condition(current_user, access)
      ticket_count = Ticket.distinct.where(access_condition).where(query, *bind_params).joins(tables).count
      tickets = Ticket.distinct.where(access_condition).where(query, *bind_params).joins(tables).limit(limit)

      return [ticket_count, tickets]
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.error e
      raise ActiveRecord::Rollback

    end
    []
  end

=begin

generate condition query to search for tickets based on condition

  query_condition, bind_condition, tables = selector2sql(params[:condition], current_user: current_user)

condition example

  {
    'ticket.title' => {
      operator: 'contains', # contains not
      value: 'some value',
    },
    'ticket.state_id' => {
      operator: 'is',
      value: [1,2,5]
    },
    'ticket.created_at' => {
      operator: 'after (absolute)', # after,before
      value: '2015-10-17T06:00:00.000Z',
    },
    'ticket.created_at' => {
      operator: 'within next (relative)', # within next, within last, after, before
      range: 'day', # minute|hour|day|month|year
      value: '25',
    },
    'ticket.owner_id' => {
      operator: 'is', # is not
      pre_condition: 'current_user.id',
    },
    'ticket.owner_id' => {
      operator: 'is', # is not
      pre_condition: 'specific',
      value: 4711,
    },
    'ticket.escalation_at' => {
      operator: 'is not', # not
      value: nil,
    },
    'ticket.tags' => {
      operator: 'contains all', # contains all|contains one|contains all not|contains one not
      value: 'tag1, tag2',
    },
  }

=end

  def self.selector2sql(selectors, options = {})
    current_user = options[:current_user]
    current_user_id = UserInfo.current_user_id
    if current_user
      current_user_id = current_user.id
    end
    return if !selectors

    # remember query and bind params
    query = ''
    bind_params = []
    like = Rails.application.config.db_like

    if selectors.respond_to?(:permit!)
      selectors = selectors.permit!.to_h
    end

    # get tables to join
    tables = ''
    selectors.each do |attribute, selector_raw|
      attributes = attribute.split('.')
      selector = selector_raw.stringify_keys
      next if !attributes[1]
      next if attributes[0] == 'execution_time'
      next if tables.include?(attributes[0])
      next if attributes[0] == 'ticket' && attributes[1] != 'mention_user_ids'
      next if attributes[0] == 'ticket' && attributes[1] == 'mention_user_ids' && selector['pre_condition'] == 'not_set'

      if query != ''
        query += ' AND '
      end
      case attributes[0]
      when 'customer'
        tables += ', users customers'
        query += 'tickets.customer_id = customers.id'
      when 'organization'
        tables += ', organizations'
        query += 'tickets.organization_id = organizations.id'
      when 'owner'
        tables += ', users owners'
        query += 'tickets.owner_id = owners.id'
      when 'article'
        tables += ', ticket_articles articles'
        query += 'tickets.id = articles.ticket_id'
      when 'ticket_state'
        tables += ', ticket_states'
        query += 'tickets.state_id = ticket_states.id'
      when 'ticket'
        if attributes[1] == 'mention_user_ids'
          tables += ', mentions'
          query += "tickets.id = mentions.mentionable_id AND mentions.mentionable_type = 'Ticket'"
        end
      else
        raise "invalid selector #{attribute.inspect}->#{attributes.inspect}"
      end
    end

    # add conditions
    no_result = false
    selectors.each do |attribute, selector_raw|

      # validation
      raise "Invalid selector #{selector_raw.inspect}" if !selector_raw
      raise "Invalid selector #{selector_raw.inspect}" if !selector_raw.respond_to?(:key?)

      selector = selector_raw.stringify_keys
      raise "Invalid selector, operator missing #{selector.inspect}" if !selector['operator']
      raise "Invalid selector, operator #{selector['operator']} is invalid #{selector.inspect}" if !selector['operator'].match?(%r{^(is|is\snot|contains|contains\s(not|all|one|all\snot|one\snot)|(after|before)\s\(absolute\)|(within\snext|within\slast|after|before|till|from)\s\(relative\))|(is\sin\sworking\stime|is\snot\sin\sworking\stime)$})

      # validate value / allow blank but only if pre_condition exists and is not specific
      if !selector.key?('value') ||
         (selector['value'].instance_of?(Array) && selector['value'].respond_to?(:blank?) && selector['value'].blank?) ||
         (selector['operator'].start_with?('contains') && selector['value'].respond_to?(:blank?) && selector['value'].blank?)
        return nil if selector['pre_condition'].nil?
        return nil if selector['pre_condition'].respond_to?(:blank?) && selector['pre_condition'].blank?
        return nil if selector['pre_condition'] == 'specific'
      end

      # validate pre_condition values
      return nil if selector['pre_condition'] && selector['pre_condition'] !~ %r{^(not_set|current_user\.|specific)}

      # get attributes
      attributes = attribute.split('.')
      attribute = "#{ActiveRecord::Base.connection.quote_table_name("#{attributes[0]}s")}.#{ActiveRecord::Base.connection.quote_column_name(attributes[1])}"

      # magic selectors
      if attributes[0] == 'ticket' && attributes[1] == 'out_of_office_replacement_id'
        attribute = "#{ActiveRecord::Base.connection.quote_table_name("#{attributes[0]}s")}.#{ActiveRecord::Base.connection.quote_column_name('owner_id')}"
      end

      if attributes[0] == 'ticket' && attributes[1] == 'tags'
        selector['value'] = selector['value'].split(',').collect(&:strip)
      end

      if selector['operator'].include?('in working time')
        next if attributes[1] != 'calendar_id'
        raise 'Please enable execution_time feature to use it (currently only allowed for triggers and schedulers)' if !options[:execution_time]

        biz = Calendar.lookup(id: selector['value'])&.biz
        next if biz.blank?

        if ( selector['operator'] == 'is in working time' && !biz.in_hours?(Time.zone.now) ) || ( selector['operator'] == 'is not in working time' && biz.in_hours?(Time.zone.now) )
          no_result = true
          break
        end

        # skip to next condition
        next
      end

      if query != ''
        query += ' AND '
      end

      # because of no grouping support we select not_set by sub select for mentions
      if attributes[0] == 'ticket' && attributes[1] == 'mention_user_ids'
        if selector['pre_condition'] == 'not_set'
          query += if selector['operator'] == 'is'
                     "(SELECT 1 FROM mentions mentions_sub WHERE mentions_sub.mentionable_type = 'Ticket' AND mentions_sub.mentionable_id = tickets.id) IS NULL"
                   else
                     "1 = (SELECT 1 FROM mentions mentions_sub WHERE mentions_sub.mentionable_type = 'Ticket' AND mentions_sub.mentionable_id = tickets.id)"
                   end
        else
          query += if selector['operator'] == 'is'
                     'mentions.user_id IN (?)'
                   else
                     'mentions.user_id NOT IN (?)'
                   end
          if selector['pre_condition'] == 'current_user.id'
            bind_params.push current_user_id
          else
            bind_params.push selector['value']
          end
        end
        next
      end

      if selector['operator'] == 'is'
        if selector['pre_condition'] == 'not_set'
          if attributes[1].match?(%r{^(created_by|updated_by|owner|customer|user)_id})
            query += "(#{attribute} IS NULL OR #{attribute} IN (?))"
            bind_params.push 1
          else
            query += "#{attribute} IS NULL"
          end
        elsif selector['pre_condition'] == 'current_user.id'
          raise "Use current_user.id in selector, but no current_user is set #{selector.inspect}" if !current_user_id

          query += "#{attribute} IN (?)"
          if attributes[1] == 'out_of_office_replacement_id'
            bind_params.push User.find(current_user_id).out_of_office_agent_of.pluck(:id)
          else
            bind_params.push current_user_id
          end
        elsif selector['pre_condition'] == 'current_user.organization_id'
          raise "Use current_user.id in selector, but no current_user is set #{selector.inspect}" if !current_user_id

          query += "#{attribute} IN (?)"
          user = User.find_by(id: current_user_id)
          bind_params.push user.organization_id
        else
          # rubocop:disable Style/IfInsideElse
          if selector['value'].nil?
            query += "#{attribute} IS NULL"
          else
            if attributes[1] == 'out_of_office_replacement_id'
              query += "#{attribute} IN (?)"
              bind_params.push User.find(selector['value']).out_of_office_agent_of.pluck(:id)
            else
              if selector['value'].class != Array
                selector['value'] = [selector['value']]
              end
              query += if selector['value'].include?('')
                         "(#{attribute} IN (?) OR #{attribute} IS NULL)"
                       else
                         "#{attribute} IN (?)"
                       end
              bind_params.push selector['value']
            end
          end
          # rubocop:enable Style/IfInsideElse
        end
      elsif selector['operator'] == 'is not'
        if selector['pre_condition'] == 'not_set'
          if attributes[1].match?(%r{^(created_by|updated_by|owner|customer|user)_id})
            query += "(#{attribute} IS NOT NULL AND #{attribute} NOT IN (?))"
            bind_params.push 1
          else
            query += "#{attribute} IS NOT NULL"
          end
        elsif selector['pre_condition'] == 'current_user.id'
          query += "(#{attribute} IS NULL OR #{attribute} NOT IN (?))"
          if attributes[1] == 'out_of_office_replacement_id'
            bind_params.push User.find(current_user_id).out_of_office_agent_of.pluck(:id)
          else
            bind_params.push current_user_id
          end
        elsif selector['pre_condition'] == 'current_user.organization_id'
          query += "(#{attribute} IS NULL OR #{attribute} NOT IN (?))"
          user = User.find_by(id: current_user_id)
          bind_params.push user.organization_id
        else
          # rubocop:disable Style/IfInsideElse
          if selector['value'].nil?
            query += "#{attribute} IS NOT NULL"
          else
            if attributes[1] == 'out_of_office_replacement_id'
              bind_params.push User.find(selector['value']).out_of_office_agent_of.pluck(:id)
              query += "(#{attribute} IS NULL OR #{attribute} NOT IN (?))"
            else
              if selector['value'].class != Array
                selector['value'] = [selector['value']]
              end
              query += if selector['value'].include?('')
                         "(#{attribute} IS NOT NULL AND #{attribute} NOT IN (?))"
                       else
                         "(#{attribute} IS NULL OR #{attribute} NOT IN (?))"
                       end
              bind_params.push selector['value']
            end
          end
          # rubocop:enable Style/IfInsideElse
        end
      elsif selector['operator'] == 'contains'
        query += "#{attribute} #{like} (?)"
        value = "%#{selector['value']}%"
        bind_params.push value
      elsif selector['operator'] == 'contains not'
        query += "#{attribute} NOT #{like} (?)"
        value = "%#{selector['value']}%"
        bind_params.push value
      elsif selector['operator'] == 'contains all' && attributes[0] == 'ticket' && attributes[1] == 'tags'
        query += "? = (
                                              SELECT
                                                COUNT(*)
                                              FROM
                                                tag_objects,
                                                tag_items,
                                                tags
                                              WHERE
                                                tickets.id = tags.o_id AND
                                                tag_objects.id = tags.tag_object_id AND
                                                tag_objects.name = 'Ticket' AND
                                                tag_items.id = tags.tag_item_id AND
                                                tag_items.name IN (?)
                                            )"
        bind_params.push selector['value'].count
        bind_params.push selector['value']
      elsif selector['operator'] == 'contains one' && attributes[0] == 'ticket' && attributes[1] == 'tags'
        tables += ', tag_objects, tag_items, tags'
        query += "
          tickets.id = tags.o_id AND
          tag_objects.id = tags.tag_object_id AND
          tag_objects.name = 'Ticket' AND
          tag_items.id = tags.tag_item_id AND
          tag_items.name IN (?)"

        bind_params.push selector['value']
      elsif selector['operator'] == 'contains all not' && attributes[0] == 'ticket' && attributes[1] == 'tags'
        query += "0 = (
                        SELECT
                          COUNT(*)
                        FROM
                          tag_objects,
                          tag_items,
                          tags
                        WHERE
                          tickets.id = tags.o_id AND
                          tag_objects.id = tags.tag_object_id AND
                          tag_objects.name = 'Ticket' AND
                          tag_items.id = tags.tag_item_id AND
                          tag_items.name IN (?)
                      )"
        bind_params.push selector['value']
      elsif selector['operator'] == 'contains one not' && attributes[0] == 'ticket' && attributes[1] == 'tags'
        query += "(
                    SELECT
                      COUNT(*)
                    FROM
                      tag_objects,
                      tag_items,
                      tags
                    WHERE
                      tickets.id = tags.o_id AND
                      tag_objects.id = tags.tag_object_id AND
                      tag_objects.name = 'Ticket' AND
                      tag_items.id = tags.tag_item_id AND
                      tag_items.name IN (?)
                  ) BETWEEN 0 AND 0"
        bind_params.push selector['value']
      elsif selector['operator'] == 'before (absolute)'
        query += "#{attribute} <= ?"
        bind_params.push selector['value']
      elsif selector['operator'] == 'after (absolute)'
        query += "#{attribute} >= ?"
        bind_params.push selector['value']
      elsif selector['operator'] == 'within last (relative)'
        query += "#{attribute} BETWEEN ? AND ?"
        time = nil
        case selector['range']
        when 'minute'
          time = selector['value'].to_i.minutes.ago
        when 'hour'
          time = selector['value'].to_i.hours.ago
        when 'day'
          time = selector['value'].to_i.days.ago
        when 'month'
          time = selector['value'].to_i.months.ago
        when 'year'
          time = selector['value'].to_i.years.ago
        else
          raise "Unknown selector attributes '#{selector.inspect}'"
        end
        bind_params.push time
        bind_params.push Time.zone.now
      elsif selector['operator'] == 'within next (relative)'
        query += "#{attribute} BETWEEN ? AND ?"
        time = nil
        case selector['range']
        when 'minute'
          time = selector['value'].to_i.minutes.from_now
        when 'hour'
          time = selector['value'].to_i.hours.from_now
        when 'day'
          time = selector['value'].to_i.days.from_now
        when 'month'
          time = selector['value'].to_i.months.from_now
        when 'year'
          time = selector['value'].to_i.years.from_now
        else
          raise "Unknown selector attributes '#{selector.inspect}'"
        end
        bind_params.push Time.zone.now
        bind_params.push time
      elsif selector['operator'] == 'before (relative)'
        query += "#{attribute} <= ?"
        time = nil
        case selector['range']
        when 'minute'
          time = selector['value'].to_i.minutes.ago
        when 'hour'
          time = selector['value'].to_i.hours.ago
        when 'day'
          time = selector['value'].to_i.days.ago
        when 'month'
          time = selector['value'].to_i.months.ago
        when 'year'
          time = selector['value'].to_i.years.ago
        else
          raise "Unknown selector attributes '#{selector.inspect}'"
        end
        bind_params.push time
      elsif selector['operator'] == 'after (relative)'
        query += "#{attribute} >= ?"
        time = nil
        case selector['range']
        when 'minute'
          time = selector['value'].to_i.minutes.from_now
        when 'hour'
          time = selector['value'].to_i.hours.from_now
        when 'day'
          time = selector['value'].to_i.days.from_now
        when 'month'
          time = selector['value'].to_i.months.from_now
        when 'year'
          time = selector['value'].to_i.years.from_now
        else
          raise "Unknown selector attributes '#{selector.inspect}'"
        end
        bind_params.push time
      elsif selector['operator'] == 'till (relative)'
        query += "#{attribute} <= ?"
        time = nil
        case selector['range']
        when 'minute'
          time = selector['value'].to_i.minutes.from_now
        when 'hour'
          time = selector['value'].to_i.hours.from_now
        when 'day'
          time = selector['value'].to_i.days.from_now
        when 'month'
          time = selector['value'].to_i.months.from_now
        when 'year'
          time = selector['value'].to_i.years.from_now
        else
          raise "Unknown selector attributes '#{selector.inspect}'"
        end
        bind_params.push time
      elsif selector['operator'] == 'from (relative)'
        query += "#{attribute} >= ?"
        time = nil
        case selector['range']
        when 'minute'
          time = selector['value'].to_i.minutes.ago
        when 'hour'
          time = selector['value'].to_i.hours.ago
        when 'day'
          time = selector['value'].to_i.days.ago
        when 'month'
          time = selector['value'].to_i.months.ago
        when 'year'
          time = selector['value'].to_i.years.ago
        else
          raise "Unknown selector attributes '#{selector.inspect}'"
        end
        bind_params.push time
      else
        raise "Invalid operator '#{selector['operator']}' for '#{selector['value'].inspect}'"
      end
    end

    return if no_result

    [query, bind_params, tables]
  end

=begin

perform changes on ticket

  ticket.perform_changes(trigger, 'trigger', item, current_user_id)

  # or

  ticket.perform_changes(job, 'job', item, current_user_id)

=end

  def perform_changes(performable, perform_origin, item = nil, current_user_id = nil)

    perform = performable.perform
    logger.debug { "Perform #{perform_origin} #{perform.inspect} on Ticket.find(#{id})" }

    article = begin
      Ticket::Article.find_by(id: item.try(:dig, :article_id))
    rescue ArgumentError
      nil
    end

    # if the configuration contains the deletion of the ticket then
    # we skip all other ticket changes because they does not matter
    if perform['ticket.action'].present? && perform['ticket.action']['value'] == 'delete'
      perform.each_key do |key|
        (object_name, attribute) = key.split('.', 2)
        next if object_name != 'ticket'
        next if attribute == 'action'

        perform.delete(key)
      end
    end

    perform_notification = {}
    perform_article = {}
    changed = false
    perform.each do |key, value|
      (object_name, attribute) = key.split('.', 2)
      raise "Unable to update object #{object_name}.#{attribute}, only can update tickets, send notifications and create articles!" if object_name != 'ticket' && object_name != 'article' && object_name != 'notification'

      # send notification/create article (after changes are done)
      if object_name == 'article'
        perform_article[key] = value
        next
      end
      if object_name == 'notification'
        perform_notification[key] = value
        next
      end

      # Apply pending_time changes
      if key == 'ticket.pending_time'
        new_value = case value['operator']
                    when 'static'
                      value['value']
                    when 'relative'
                      pendtil = Time.zone.now
                      val     = value['value'].to_i

                      case value['range']
                      when 'day'
                        pendtil += val.days
                      when 'minute'
                        pendtil += val.minutes
                      when 'hour'
                        pendtil += val.hours
                      when 'month'
                        pendtil += val.months
                      when 'year'
                        pendtil += val.years
                      end

                      pendtil
                    end

        if new_value
          self[attribute] = new_value
          changed = true
          next
        end
      end

      # update tags
      if key == 'ticket.tags'
        next if value['value'].blank?

        tags = value['value'].split(',')
        case value['operator']
        when 'add'
          tags.each do |tag|
            tag_add(tag, current_user_id || 1)
          end
        when 'remove'
          tags.each do |tag|
            tag_remove(tag, current_user_id || 1)
          end
        else
          logger.error "Unknown #{attribute} operator #{value['operator']}"
        end
        next
      end

      # delete ticket
      if key == 'ticket.action'
        next if value['value'].blank?
        next if value['value'] != 'delete'

        logger.info { "Deleted ticket from #{perform_origin} #{perform.inspect} Ticket.find(#{id})" }
        destroy!
        next
      end

      # lookup pre_condition
      if value['pre_condition']
        if value['pre_condition'].start_with?('not_set')
          value['value'] = 1
        elsif value['pre_condition'].start_with?('current_user.')
          raise 'Unable to use current_user, got no current_user_id for ticket.perform_changes' if !current_user_id

          value['value'] = current_user_id
        end
      end

      # update ticket
      next if self[attribute].to_s == value['value'].to_s

      changed = true

      self[attribute] = value['value']
      logger.debug { "set #{object_name}.#{attribute} = #{value['value'].inspect} for ticket_id #{id}" }
    end

    if changed
      save!
    end

    objects = build_notification_template_objects(article)

    perform_article.each do |key, value|
      raise 'Unable to create article, we only support article.note' if key != 'article.note'

      add_trigger_note(id, value, objects, perform_origin)
    end

    perform_notification.each do |key, value|

      # send notification
      case key
      when 'notification.sms'
        send_sms_notification(value, article, perform_origin)
        next
      when 'notification.email'
        send_email_notification(value, article, perform_origin)
      when 'notification.webhook'
        TriggerWebhookJob.perform_later(performable, self, article)
      end
    end

    true
  end

=begin

perform changes on ticket

  ticket.add_trigger_note(ticket_id, note, objects, perform_origin)

=end

  def add_trigger_note(ticket_id, note, objects, perform_origin)
    rendered_subject = NotificationFactory::Mailer.template(
      templateInline: note[:subject],
      objects:        objects,
      quote:          true,
    )

    rendered_body = NotificationFactory::Mailer.template(
      templateInline: note[:body],
      objects:        objects,
      quote:          true,
    )

    Ticket::Article.create!(
      ticket_id:     ticket_id,
      subject:       rendered_subject,
      content_type:  'text/html',
      body:          rendered_body,
      internal:      note[:internal],
      sender:        Ticket::Article::Sender.find_by(name: 'System'),
      type:          Ticket::Article::Type.find_by(name: 'note'),
      preferences:   {
        perform_origin: perform_origin,
      },
      updated_by_id: 1,
      created_by_id: 1,
    )
  end

=begin

perform active triggers on ticket

  Ticket.perform_triggers(ticket, article, item, options)

=end

  def self.perform_triggers(ticket, article, item, options = {})
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

    triggers = if Rails.configuration.db_case_sensitive
                 ::Trigger.where(active: true).order(Arel.sql('LOWER(name)'))
               else
                 ::Trigger.where(active: true).order(:name)
               end
    return [true, 'No triggers active'] if triggers.blank?

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

        condition = trigger.condition

        # check if one article attribute is used
        one_has_changed_done = false
        article_selector = false
        trigger.condition.each_key do |key|
          (object_name, attribute) = key.split('.', 2)
          next if object_name != 'article'
          next if attribute == 'id'

          article_selector = true
        end
        if article && article_selector
          one_has_changed_done = true
        end
        if article && type == 'update'
          one_has_changed_done = true
        end

        # check ticket "has changed" options
        has_changed_done = true
        condition.each do |key, value|
          next if value.blank?
          next if value['operator'].blank?
          next if !value['operator']['has changed']

          # remove condition item, because it has changed
          (object_name, attribute) = key.split('.', 2)
          next if object_name != 'ticket'
          next if item[:changes].blank?
          next if !item[:changes].key?(attribute)

          condition.delete(key)
          one_has_changed_done = true
        end

        # check if we have not matching "has changed" attributes
        condition.each_value do |value|
          next if value.blank?
          next if value['operator'].blank?
          next if !value['operator']['has changed']

          has_changed_done = false
          break
        end

        # check ticket action
        if condition['ticket.action']
          next if condition['ticket.action']['operator'] == 'is' && condition['ticket.action']['value'] != type
          next if condition['ticket.action']['operator'] != 'is' && condition['ticket.action']['value'] == type

          condition.delete('ticket.action')
        end
        next if !has_changed_done

        # check in min one attribute of condition has changed on update
        one_has_changed_condition = false
        if type == 'update'

          # verify if ticket condition exists
          condition.each_key do |key|
            (object_name, attribute) = key.split('.', 2)
            next if object_name != 'ticket'

            one_has_changed_condition = true
            next if item[:changes].blank?
            next if !item[:changes].key?(attribute)

            one_has_changed_done = true
            break
          end
          next if one_has_changed_condition && !one_has_changed_done
        end

        # check if ticket selector is matching
        condition['ticket.id'] = {
          operator: 'is',
          value:    ticket.id,
        }
        next if article_selector && !article

        # check if article selector is matching
        if article_selector
          condition['article.id'] = {
            operator: 'is',
            value:    article.id,
          }
        end

        user_id = ticket.updated_by_id
        if article
          user_id = article.updated_by_id
        end

        user = if user_id != 1
                 User.lookup(id: user_id)
               end

        # verify is condition is matching
        ticket_count, tickets = Ticket.selectors(condition, limit: 1, execution_time: true, current_user: user, access: 'ignore')

        next if ticket_count.blank?
        next if ticket_count.zero?
        next if tickets.first.id != ticket.id

        if recursive == false && local_options[:loop_count] > 1
          message = "Do not execute recursive triggers per default until Zammad 3.0. With Zammad 3.0 and higher the following trigger is executed '#{trigger.name}' on Ticket:#{ticket.id}. Please review your current triggers and change them if needed."
          logger.info { message }
          return [true, message]
        end

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

        ticket.perform_changes(trigger, 'trigger', item, user_id)

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

  def get_references(ignore = [])
    references = []
    Ticket::Article.select('in_reply_to, message_id').where(ticket_id: id).each do |article|
      if article.in_reply_to.present?
        references.push article.in_reply_to
      end
      next if article.message_id.blank?

      references.push article.message_id
    end
    ignore.each do |item|
      references.delete(item)
    end
    references
  end

=begin

get all articles of a ticket in correct order (overwrite active record default method)

  articles = ticket.articles

result

  [article1, article2]

=end

  def articles
    Ticket::Article.where(ticket_id: id).order(:created_at, :id)
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
    if !owner_id
      self.owner_id = 1
    end
    return true if !customer_id

    customer = User.find_by(id: customer_id)
    return true if !customer
    return true if organization_id == customer.organization_id

    self.organization_id = customer.organization_id
    true
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

  # articles.last breaks (returns the wrong article)
  # if another email notification trigger preceded this one
  # (see https://github.com/zammad/zammad/issues/1543)
  def build_notification_template_objects(article)
    {
      ticket:  self,
      article: article || articles.last
    }
  end

  def send_email_notification(value, article, perform_origin)
    # value['recipient'] was a string in the past (single-select) so we convert it to array if needed
    value_recipient = Array(value['recipient'])

    recipients_raw = []
    value_recipient.each do |recipient|
      case recipient
      when 'article_last_sender'
        if article.present?
          if article.reply_to.present?
            recipients_raw.push(article.reply_to)
          elsif article.from.present?
            recipients_raw.push(article.from)
          elsif article.origin_by_id
            email = User.find_by(id: article.origin_by_id).email
            recipients_raw.push(email)
          elsif article.created_by_id
            email = User.find_by(id: article.created_by_id).email
            recipients_raw.push(email)
          end
        end
      when 'ticket_customer'
        email = User.find_by(id: customer_id).email
        recipients_raw.push(email)
      when 'ticket_owner'
        email = User.find_by(id: owner_id).email
        recipients_raw.push(email)
      when 'ticket_agents'
        User.group_access(group_id, 'full').sort_by(&:login).each do |user|
          recipients_raw.push(user.email)
        end
      when %r{\Auserid_(\d+)\z}
        user = User.lookup(id: $1)
        if !user
          logger.warn "Can't find configured Trigger Email recipient User with ID '#{$1}'"
          next
        end
        recipients_raw.push(user.email)
      else
        logger.error "Unknown email notification recipient '#{recipient}'"
        next
      end
    end

    recipients_checked = []
    recipients_raw.each do |recipient_email|

      users = User.where(email: recipient_email)
      next if users.any? { |user| !trigger_based_notification?(user) }

      # send notifications only to email addresses
      next if recipient_email.blank?

      # check if address is valid
      begin
        Mail::AddressList.new(recipient_email).addresses.each do |address|
          recipient_email = address.address
          email_address_validation = EmailAddressValidation.new(recipient_email)
          break if recipient_email.present? && email_address_validation.valid_format?
        end
      rescue
        if recipient_email.present?
          if recipient_email !~ %r{^(.+?)<(.+?)@(.+?)>$}
            next # no usable format found
          end

          recipient_email = "#{$2}@#{$3}" # rubocop:disable Lint/OutOfRangeRegexpRef
        end
      end

      email_address_validation = EmailAddressValidation.new(recipient_email)
      next if !email_address_validation.valid_format?

      # do not send notification if system address
      next if EmailAddress.exists?(email: recipient_email.downcase)

      # do not sent notifications to this recipients
      send_no_auto_response_reg_exp = Setting.get('send_no_auto_response_reg_exp')
      begin
        next if recipient_email.match?(%r{#{send_no_auto_response_reg_exp}}i)
      rescue => e
        logger.error "Invalid regex '#{send_no_auto_response_reg_exp}' in setting send_no_auto_response_reg_exp"
        logger.error e
        next if recipient_email.match?(%r{(mailer-daemon|postmaster|abuse|root|noreply|noreply.+?|no-reply|no-reply.+?)@.+?}i)
      end

      # check if notification should be send because of customer emails
      if article.present? && article.preferences.fetch('is-auto-response', false) == true && article.from && article.from =~ %r{#{Regexp.quote(recipient_email)}}i
        logger.info "Send no trigger based notification to #{recipient_email} because of auto response tagged incoming email"
        next
      end

      # loop protection / check if maximal count of trigger mail has reached
      map = {
        10  => 10,
        30  => 15,
        60  => 25,
        180 => 50,
        600 => 100,
      }
      skip = false
      map.each do |minutes, count|
        already_sent = Ticket::Article.where(
          ticket_id: id,
          sender:    Ticket::Article::Sender.find_by(name: 'System'),
          type:      Ticket::Article::Type.find_by(name: 'email'),
        ).where('ticket_articles.created_at > ? AND ticket_articles.to LIKE ?', Time.zone.now - minutes.minutes, "%#{recipient_email.strip}%").count
        next if already_sent < count

        logger.info "Send no trigger based notification to #{recipient_email} because already sent #{count} for this ticket within last #{minutes} minutes (loop protection)"
        skip = true
        break
      end
      next if skip

      map = {
        10  => 30,
        30  => 60,
        60  => 120,
        180 => 240,
        600 => 360,
      }
      skip = false
      map.each do |minutes, count|
        already_sent = Ticket::Article.where(
          sender: Ticket::Article::Sender.find_by(name: 'System'),
          type:   Ticket::Article::Type.find_by(name: 'email'),
        ).where('ticket_articles.created_at > ? AND ticket_articles.to LIKE ?', Time.zone.now - minutes.minutes, "%#{recipient_email.strip}%").count
        next if already_sent < count

        logger.info "Send no trigger based notification to #{recipient_email} because already sent #{count} in total within last #{minutes} minutes (loop protection)"
        skip = true
        break
      end
      next if skip

      email = recipient_email.downcase.strip
      next if recipients_checked.include?(email)

      recipients_checked.push(email)
    end

    return if recipients_checked.blank?

    recipient_string = recipients_checked.join(', ')

    group_id = self.group_id
    return if !group_id

    email_address = Group.find(group_id).email_address
    if !email_address
      logger.info "Unable to send trigger based notification to #{recipient_string} because no email address is set for group '#{group.name}'"
      return
    end

    if !email_address.channel_id
      logger.info "Unable to send trigger based notification to #{recipient_string} because no channel is set for email address '#{email_address.email}' (id: #{email_address.id})"
      return
    end

    security = nil
    if Setting.get('smime_integration')
      sign       = value['sign'].present? && value['sign'] != 'no'
      encryption = value['encryption'].present? && value['encryption'] != 'no'
      security   = {
        type:       'S/MIME',
        sign:       {
          success: false,
        },
        encryption: {
          success: false,
        },
      }

      if sign
        sign_found = false
        begin
          list = Mail::AddressList.new(email_address.email)
          from = list.addresses.first.to_s
          cert = SMIMECertificate.for_sender_email_address(from)
          if cert && !cert.expired?
            sign_found                = true
            security[:sign][:success] = true
            security[:sign][:comment] = "certificate for #{email_address.email} found"
          end
        rescue # rubocop:disable Lint/SuppressedException
        end

        if value['sign'] == 'discard' && !sign_found
          logger.info "Unable to send trigger based notification to #{recipient_string} because of missing group #{group.name} email #{email_address.email} certificate for signing (discarding notification)."
          return
        end
      end

      if encryption
        certs_found = false
        begin
          SMIMECertificate.for_recipipent_email_addresses!(recipients_checked)
          certs_found                     = true
          security[:encryption][:success] = true
          security[:encryption][:comment] = "certificates found for #{recipient_string}"
        rescue # rubocop:disable Lint/SuppressedException
        end

        if value['encryption'] == 'discard' && !certs_found
          logger.info "Unable to send trigger based notification to #{recipient_string} because public certificate is not available for encryption (discarding notification)."
          return
        end
      end
    end

    objects = build_notification_template_objects(article)

    # get subject
    subject = NotificationFactory::Mailer.template(
      templateInline: value['subject'],
      objects:        objects,
      quote:          false,
    )
    subject = subject_build(subject)

    body = NotificationFactory::Mailer.template(
      templateInline: value['body'],
      objects:        objects,
      quote:          true,
    )

    (body, attachments_inline) = HtmlSanitizer.replace_inline_images(body, id)

    preferences                  = {}
    preferences[:perform_origin] = perform_origin
    if security.present?
      preferences[:security] = security
    end

    message = Ticket::Article.create(
      ticket_id:     id,
      to:            recipient_string,
      subject:       subject,
      content_type:  'text/html',
      body:          body,
      internal:      value['internal'] || false, # default to public if value was not set
      sender:        Ticket::Article::Sender.find_by(name: 'System'),
      type:          Ticket::Article::Type.find_by(name: 'email'),
      preferences:   preferences,
      updated_by_id: 1,
      created_by_id: 1,
    )

    attachments_inline.each do |attachment|
      Store.add(
        object:      'Ticket::Article',
        o_id:        message.id,
        data:        attachment[:data],
        filename:    attachment[:filename],
        preferences: attachment[:preferences],
      )
    end

    original_article = objects[:article]
    if original_article&.should_clone_inline_attachments? # rubocop:disable Style/GuardClause
      original_article.clone_attachments('Ticket::Article', message.id, only_inline_attachments: true)
      original_article.should_clone_inline_attachments = false # cancel the temporary flag after cloning
    end
  end

  def sms_recipients_by_type(recipient_type, article)
    case recipient_type
    when 'article_last_sender'
      return nil if article.blank?

      if article.origin_by_id
        article.origin_by_id
      elsif article.created_by_id
        article.created_by_id
      end
    when 'ticket_customer'
      customer_id
    when 'ticket_owner'
      owner_id
    when 'ticket_agents'
      User.group_access(group_id, 'full').sort_by(&:login)
    when %r{\Auserid_(\d+)\z}
      return $1 if User.exists?($1)

      logger.warn "Can't find configured Trigger SMS recipient User with ID '#{$1}'"
      nil
    else
      logger.error "Unknown sms notification recipient '#{recipient}'"
      nil
    end
  end

  def build_sms_recipients_list(value, article)
    Array(value['recipient'])
      .each_with_object([]) { |recipient_type, sum| sum.concat(Array(sms_recipients_by_type(recipient_type, article))) }
      .map { |user_or_id| user_or_id.is_a?(User) ? user_or_id : User.lookup(id: user_or_id) }
      .uniq(&:id)
      .select { |user| user.mobile.present? }
  end

  def send_sms_notification(value, article, perform_origin)
    sms_recipients = build_sms_recipients_list(value, article)

    if sms_recipients.blank?
      logger.debug "No SMS recipients found for Ticket# #{number}"
      return
    end

    sms_recipients_to = sms_recipients
                        .map { |recipient| "#{recipient.fullname} (#{recipient.mobile})" }
                        .join(', ')

    channel = Channel.find_by(area: 'Sms::Notification')
    if !channel.active?
      # write info message since we have an active trigger
      logger.info "Found possible SMS recipient(s) (#{sms_recipients_to}) for Ticket# #{number} but SMS channel is not active."
      return
    end

    objects = build_notification_template_objects(article)
    body = NotificationFactory::Renderer.new(
      objects:  objects,
      template: value['body'],
      escape:   false
    ).render.html2text.tr(' ', ' ') # convert non-breaking space to simple space

    # attributes content_type is not needed for SMS
    Ticket::Article.create(
      ticket_id:     id,
      subject:       'SMS notification',
      to:            sms_recipients_to,
      body:          body,
      internal:      value['internal'] || false, # default to public if value was not set
      sender:        Ticket::Article::Sender.find_by(name: 'System'),
      type:          Ticket::Article::Type.find_by(name: 'sms'),
      preferences:   {
        perform_origin: perform_origin,
        sms_recipients: sms_recipients.map(&:mobile),
        channel_id:     channel.id,
      },
      updated_by_id: 1,
      created_by_id: 1,
    )
  end

  def trigger_based_notification?(user)
    blocked_in_days = trigger_based_notification_blocked_in_days(user)
    return true if blocked_in_days.zero?

    logger.info "Send no trigger based notification to #{user.email} because email is marked as mail_delivery_failed for #{blocked_in_days} day(s)"
    false
  end

  def trigger_based_notification_blocked_in_days(user)
    return 0 if !user.preferences[:mail_delivery_failed]
    return 0 if user.preferences[:mail_delivery_failed_data].blank?

    # blocked for 60 full days
    (user.preferences[:mail_delivery_failed_data].to_date - Time.zone.now.to_date).to_i + 61
  end
end
