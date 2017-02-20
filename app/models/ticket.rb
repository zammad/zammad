# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Ticket < ApplicationModel
  include LogsActivityStream
  include NotifiesClients
  include LatestChangeObserved
  include Historisable
  include SearchIndexed

  include Ticket::Escalation
  include Ticket::Subject
  load 'ticket/permission.rb'
  include Ticket::Permission
  load 'ticket/assets.rb'
  include Ticket::Assets
  load 'ticket/search_index.rb'
  include Ticket::SearchIndex
  extend Ticket::Search

  store          :preferences
  before_create  :check_generate, :check_defaults, :check_title, :check_escalation_update, :set_default_state, :set_default_priority
  before_update  :check_defaults, :check_title, :reset_pending_time, :check_escalation_update
  before_destroy :destroy_dependencies

  validates :group_id, presence: true

  activity_stream_permission 'ticket.agent'

  activity_stream_attributes_ignored :organization_id, # organization_id will channge automatically on user update
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
                                     :preferences

  history_attributes_ignored :create_article_type_id,
                             :create_article_sender_id,
                             :article_count,
                             :preferences

  belongs_to    :group,                 class_name: 'Group'
  has_many      :articles,              class_name: 'Ticket::Article', after_add: :cache_update, after_remove: :cache_update
  belongs_to    :organization,          class_name: 'Organization'
  belongs_to    :state,                 class_name: 'Ticket::State'
  belongs_to    :priority,              class_name: 'Ticket::Priority'
  belongs_to    :owner,                 class_name: 'User'
  belongs_to    :customer,              class_name: 'User'
  belongs_to    :created_by,            class_name: 'User'
  belongs_to    :updated_by,            class_name: 'User'
  belongs_to    :create_article_type,   class_name: 'Ticket::Article::Type'
  belongs_to    :create_article_sender, class_name: 'Ticket::Article::Sender'

  self.inheritance_column = nil

  attr_accessor :callback_loop

=begin

list of agents in group of ticket

  ticket = Ticket.find(123)
  result = ticket.agent_of_group

returns

  result = [user1, user2, ...]

=end

  def agent_of_group
    roles = Role.with_permissions('ticket.agent')
    role_ids = roles.map(&:id)
    Group.find(group_id)
         .users.where(active: true)
         .joins(:roles)
         .where('roles.id' => role_ids, 'roles.active' => true)
         .order('users.login')
         .uniq()
  end

=begin

get user access conditions

  conditions = Ticket.access_condition( User.find(1) )

returns

  result = [user1, user2, ...]

=end

  def self.access_condition(user)
    access_condition = []
    if user.permissions?('ticket.agent')
      group_ids = Group.select('groups.id').joins(:users)
                       .where('groups_users.user_id = ?', user.id)
                       .where('groups.active = ?', true)
                       .map(&:id)
      access_condition = [ '(group_id IN (?) OR tickets.customer_id = ?) ', group_ids, user.id ]
    else
      access_condition = if !user.organization || ( !user.organization.shared || user.organization.shared == false )
                           [ 'tickets.customer_id = ?', user.id ]
                         else
                           [ '(tickets.customer_id = ? OR tickets.organization_id = ?)', user.id, user.organization.id ]
                         end
    end
    access_condition
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
    if !ticket_states_pending_action.empty?
      next_state_map = {}
      ticket_states_pending_action.each { |state|
        next_state_map[state.id] = state.next_state_id
      }

      tickets = where(state_id: next_state_map.keys)
                .where('pending_time <= ?', Time.zone.now)

      tickets.each { |ticket|
        Transaction.execute do
          ticket.state_id      = next_state_map[ticket.state_id]
          ticket.updated_at    = Time.zone.now
          ticket.updated_by_id = 1
          ticket.save!
        end
        result.push ticket
      }
    end

    # process pending reminder tickets
    pending_reminder = Ticket::StateType.find_by(name: 'pending reminder')
    ticket_states_pending_reminder = Ticket::State.where(state_type_id: pending_reminder)

    if !ticket_states_pending_reminder.empty?
      reminder_state_map = {}
      ticket_states_pending_reminder.each { |state|
        reminder_state_map[state.id] = state.next_state_id
      }

      tickets = where(state_id: reminder_state_map.keys)
                .where('pending_time <= ?', Time.zone.now)

      tickets.each { |ticket|

        article_id = nil
        article = Ticket::Article.last_customer_agent_article(ticket.id)
        if article
          article_id = article.id
        end

        # send notification
        Transaction::BackgroundJob.run(
          object: 'Ticket',
          type: 'reminder_reached',
          object_id: ticket.id,
          article_id: article_id,
          user_id: 1,
        )

        result.push ticket
      }
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

    # get max warning diff

    tickets = where('escalation_at <= ?', Time.zone.now + 15.minutes)

    tickets.each { |ticket|

      # get sla
      sla = ticket.escalation_calculation_get_sla

      article_id = nil
      article = Ticket::Article.last_customer_agent_article(ticket.id)
      if article
        article_id = article.id
      end

      # send escalation
      if ticket.escalation_at < Time.zone.now
        Transaction::BackgroundJob.run(
          object: 'Ticket',
          type: 'escalation',
          object_id: ticket.id,
          article_id: article_id,
          user_id: 1,
        )
        result.push ticket
        next
      end

      # check if warning need to be sent
      Transaction::BackgroundJob.run(
        object: 'Ticket',
        type: 'escalation_warning',
        object_id: ticket.id,
        article_id: article_id,
        user_id: 1,
      )
      result.push ticket
    }
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

    # update articles
    Transaction.execute do

      Ticket::Article.where(ticket_id: id).each(&:touch)

      # quiet update of reassign of articles
      Ticket::Article.where(ticket_id: id).update_all(['ticket_id = ?', data[:ticket_id]])

      # update history

      # create new merge article
      Ticket::Article.create(
        ticket_id: id,
        type_id: Ticket::Article::Type.lookup(name: 'note').id,
        sender_id: Ticket::Article::Sender.lookup(name: 'Agent').id,
        body: 'merged',
        internal: false,
        created_by_id: data[:user_id],
        updated_by_id: data[:user_id],
      )

      # add history to both

      # link tickets
      Link.add(
        link_type: 'parent',
        link_object_source: 'Ticket',
        link_object_source_value: data[:ticket_id],
        link_object_target: 'Ticket',
        link_object_target_value: id
      )

      # set state to 'merged'
      self.state_id = Ticket::State.lookup(name: 'merged').id

      # rest owner
      self.owner_id = User.find_by(login: '-').id

      # save ticket
      save!

      # touch new ticket (to broadcast change)
      Ticket.find(data[:ticket_id]).touch
    end
    true
  end

=begin

check if online notifcation should be shown in general as already seen with current state

  ticket = Ticket.find(1)
  seen = ticket.online_notification_seen_state(user_id_check)

returns

  result = true # or false

check if online notifcation should be shown for this user as already seen with current state

  ticket = Ticket.find(1)
  seen = ticket.online_notification_seen_state(check_user_id)

returns

  result = true # or false

=end

  def online_notification_seen_state(user_id_check = nil)
    state      = Ticket::State.lookup(id: state_id)
    state_type = Ticket::StateType.lookup(id: state.state_type_id)

    # always to set unseen for ticket owner
    if state_type.name != 'merged'
      if user_id_check
        return false if user_id_check == owner_id && user_id_check != updated_by_id
      end
    end

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

  ticket_count, tickets = Ticket.selectors(params[:condition], limit, current_user)

=end

  def self.selectors(selectors, limit = 10, current_user = nil)
    raise 'no selectors given' if !selectors
    query, bind_params, tables = selector2sql(selectors, current_user)
    return [] if !query

    if !current_user
      ticket_count = Ticket.where(query, *bind_params).joins(tables).count
      tickets = Ticket.where(query, *bind_params).joins(tables).limit(limit)
      return [ticket_count, tickets]
    end

    access_condition = Ticket.access_condition(current_user)
    ticket_count = Ticket.where(access_condition).where(query, *bind_params).joins(tables).count
    tickets = Ticket.where(access_condition).where(query, *bind_params).joins(tables).limit(limit)
    [ticket_count, tickets]
  end

=begin

generate condition query to search for tickets based on condition

  query_condition, bind_condition, tables = selector2sql(params[:condition], current_user)

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
      operator: 'within next (relative)', # before,within,in,after
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
    }
  }

=end

  def self.selector2sql(selectors, current_user = nil)
    current_user_id = UserInfo.current_user_id
    if current_user
      current_user_id = current_user.id
    end
    return if !selectors

    # remember query and bind params
    query = ''
    bind_params = []
    like = Rails.application.config.db_like

    # get tables to join
    tables = ''
    selectors.each { |attribute, selector|
      selector = attribute.split(/\./)
      next if !selector[1]
      next if selector[0] == 'ticket'
      next if tables.include?(selector[0])
      if query != ''
        query += ' AND '
      end
      if selector[0] == 'customer'
        tables += ', users customers'
        query += 'tickets.customer_id = customers.id'
      elsif selector[0] == 'organization'
        tables += ', organizations'
        query += 'tickets.organization_id = organizations.id'
      elsif selector[0] == 'owner'
        tables += ', users owners'
        query += 'tickets.owner_id = owners.id'
      elsif selector[0] == 'article'
        tables += ', ticket_articles articles'
        query += 'tickets.id = articles.ticket_id'
      else
        raise "invalid selector #{attribute.inspect}->#{selector.inspect}"
      end
    }

    # add conditions
    selectors.each { |attribute, selector_raw|

      # validation
      raise "Invalid selector #{selector_raw.inspect}" if !selector_raw
      raise "Invalid selector #{selector_raw.inspect}" if !selector_raw.respond_to?(:key?)
      selector = selector_raw.stringify_keys
      raise "Invalid selector, operator missing #{selector.inspect}" if !selector['operator']

      # validate value / allow empty but only if pre_condition exists and is not specific
      if !selector.key?('value') || ((selector['value'].class == String || selector['value'].class == Array) && (selector['value'].respond_to?(:empty?) && selector['value'].empty?))
        return nil if selector['pre_condition'].nil?
        return nil if selector['pre_condition'].respond_to?(:empty?) && selector['pre_condition'].empty?
        return nil if selector['pre_condition'] == 'specific'
      end

      # validate pre_condition values
      return nil if selector['pre_condition'] && selector['pre_condition'] !~ /^(not_set|current_user\.|specific)/

      # get attributes
      attributes = attribute.split(/\./)
      attribute = "#{attributes[0]}s.#{attributes[1]}"

      if query != ''
        query += ' AND '
      end

      if selector['operator'] == 'is'
        if selector['pre_condition'] == 'not_set'
          if attributes[1] =~ /^(created_by|updated_by|owner|customer|user)_id/
            query += "#{attribute} IN (?)"
            bind_params.push 1
          else
            query += "#{attribute} IS NOT NULL"
          end
        elsif selector['pre_condition'] == 'current_user.id'
          raise "Use current_user.id in selector, but no current_user is set #{selector.inspect}" if !current_user_id
          query += "#{attribute} IN (?)"
          bind_params.push current_user_id
        elsif selector['pre_condition'] == 'current_user.organization_id'
          raise "Use current_user.id in selector, but no current_user is set #{selector.inspect}" if !current_user_id
          query += "#{attribute} IN (?)"
          user = User.lookup(id: current_user_id)
          bind_params.push user.organization_id
        else
          # rubocop:disable Style/IfInsideElse
          if selector['value'].nil?
            query += "#{attribute} IS NOT NULL"
          else
            query += "#{attribute} IN (?)"
            bind_params.push selector['value']
          end
          # rubocop:enable Style/IfInsideElse
        end
      elsif selector['operator'] == 'is not'
        if selector['pre_condition'] == 'not_set'
          if attributes[1] =~ /^(created_by|updated_by|owner|customer|user)_id/
            query += "#{attribute} NOT IN (?)"
            bind_params.push 1
          else
            query += "#{attribute} IS NULL"
          end
        elsif selector['pre_condition'] == 'current_user.id'
          query += "#{attribute} NOT IN (?)"
          bind_params.push current_user_id
        elsif selector['pre_condition'] == 'current_user.organization_id'
          query += "#{attribute} NOT IN (?)"
          user = User.lookup(id: current_user_id)
          bind_params.push user.organization_id
        else
          # rubocop:disable Style/IfInsideElse
          if selector['value'].nil?
            query += "#{attribute} IS NOT NULL"
          else
            query += "#{attribute} NOT IN (?)"
            bind_params.push selector['value']
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
      elsif selector['operator'] == 'before (absolute)'
        query += "#{attribute} <= ?"
        bind_params.push selector['value']
      elsif selector['operator'] == 'after (absolute)'
        query += "#{attribute} >= ?"
        bind_params.push selector['value']
      elsif selector['operator'] == 'within last (relative)'
        query += "#{attribute} >= ?"
        time = nil
        if selector['range'] == 'minute'
          time = Time.zone.now - selector['value'].to_i.minutes
        elsif selector['range'] == 'hour'
          time = Time.zone.now - selector['value'].to_i.hours
        elsif selector['range'] == 'day'
          time = Time.zone.now - selector['value'].to_i.days
        elsif selector['range'] == 'month'
          time = Time.zone.now - selector['value'].to_i.months
        elsif selector['range'] == 'year'
          time = Time.zone.now - selector['value'].to_i.years
        else
          raise "Unknown selector attributes '#{selector.inspect}'"
        end
        bind_params.push time
      elsif selector['operator'] == 'within next (relative)'
        query += "#{attribute} <= ?"
        time = nil
        if selector['range'] == 'minute'
          time = Time.zone.now + selector['value'].to_i.minutes
        elsif selector['range'] == 'hour'
          time = Time.zone.now + selector['value'].to_i.hours
        elsif selector['range'] == 'day'
          time = Time.zone.now + selector['value'].to_i.days
        elsif selector['range'] == 'month'
          time = Time.zone.now + selector['value'].to_i.months
        elsif selector['range'] == 'year'
          time = Time.zone.now + selector['value'].to_i.years
        else
          raise "Unknown selector attributes '#{selector.inspect}'"
        end
        bind_params.push time
      elsif selector['operator'] == 'before (relative)'
        query += "#{attribute} <= ?"
        time = nil
        if selector['range'] == 'minute'
          time = Time.zone.now - selector['value'].to_i.minutes
        elsif selector['range'] == 'hour'
          time = Time.zone.now - selector['value'].to_i.hours
        elsif selector['range'] == 'day'
          time = Time.zone.now - selector['value'].to_i.days
        elsif selector['range'] == 'month'
          time = Time.zone.now - selector['value'].to_i.months
        elsif selector['range'] == 'year'
          time = Time.zone.now - selector['value'].to_i.years
        else
          raise "Unknown selector attributes '#{selector.inspect}'"
        end
        bind_params.push time
      elsif selector['operator'] == 'after (relative)'
        query += "#{attribute} >= ?"
        time = nil
        if selector['range'] == 'minute'
          time = Time.zone.now + selector['value'].to_i.minutes
        elsif selector['range'] == 'hour'
          time = Time.zone.now + selector['value'].to_i.hours
        elsif selector['range'] == 'day'
          time = Time.zone.now + selector['value'].to_i.days
        elsif selector['range'] == 'month'
          time = Time.zone.now + selector['value'].to_i.months
        elsif selector['range'] == 'year'
          time = Time.zone.now + selector['value'].to_i.years
        else
          raise "Unknown selector attributes '#{selector.inspect}'"
        end
        bind_params.push time
      else
        raise "Invalid operator '#{selector['operator']}' for '#{selector['value'].inspect}'"
      end
    }
    [query, bind_params, tables]
  end

=begin

perform changes on ticket

  ticket.perform_changes({}, 'trigger', item)

=end

  def perform_changes(perform, perform_origin, item = nil)
    logger.debug "Perform #{perform_origin} #{perform.inspect} on Ticket.find(#{id})"
    changed = false
    perform.each do |key, value|
      (object_name, attribute) = key.split('.', 2)
      raise "Unable to update object #{object_name}.#{attribute}, only can update tickets and send notifications!" if object_name != 'ticket' && object_name != 'notification'

      # send notification
      if object_name == 'notification'
        recipients = []
        if value['recipient'] == 'ticket_customer'
          recipients.push User.lookup(id: customer_id)
        elsif value['recipient'] == 'ticket_owner'
          recipients.push User.lookup(id: owner_id)
        elsif value['recipient'] == 'ticket_agents'
          recipients = recipients.concat(agent_of_group)
        else
          logger.error "Unknown email notification recipient '#{value['recipient']}'"
          next
        end
        recipient_string = ''
        recipient_already = {}
        recipients.each { |user|

          # send notifications only to email adresses
          next if !user.email
          next if user.email !~ /@/

          # do not sent notifications to this recipients
          send_no_auto_response_reg_exp = Setting.get('send_no_auto_response_reg_exp')
          begin
            next if user.email =~ /#{send_no_auto_response_reg_exp}/i
          rescue => e
            logger.error "ERROR: Invalid regex '#{send_no_auto_response_reg_exp}' in setting send_no_auto_response_reg_exp"
            logger.error 'ERROR: ' + e.inspect
            next if user.email =~ /(mailer-daemon|postmaster|abuse|root)@.+?\..+?/i
          end

          # check if notification should be send because of customer emails
          if item && item[:article_id]
            article = Ticket::Article.lookup(id: item[:article_id])
            if article && article.preferences['is-auto-response'] == true && article.from && article.from =~ /#{Regexp.quote(user.email)}/i
              logger.info "Send not trigger based notification to #{user.email} because of auto response tagged incoming email"
              next
            end
          end

          email = user.email.downcase.strip
          next if recipient_already[email]
          recipient_already[email] = true
          if recipient_string != ''
            recipient_string += ', '
          end
          recipient_string += email
        }
        next if recipient_string == ''
        group = self.group
        next if !group
        email_address = group.email_address
        next if !email_address
        next if !email_address.channel_id

        objects = {
          ticket: self,
          article: articles.last,
          #recipient: user,
          #changes: changes,
        }

        # get subject
        subject = NotificationFactory::Mailer.template(
          templateInline: value['subject'],
          locale: 'en-en',
          objects: objects,
          quote: false,
        )
        subject = subject_build(subject)

        body = NotificationFactory::Mailer.template(
          templateInline: value['body'],
          locale: 'en-en',
          objects: objects,
          quote: true,
        )

        Ticket::Article.create(
          ticket_id: id,
          to: recipient_string,
          subject: subject,
          content_type: 'text/html',
          body: body,
          internal: false,
          sender: Ticket::Article::Sender.find_by(name: 'System'),
          type: Ticket::Article::Type.find_by(name: 'email'),
          preferences: {
            perform_origin: perform_origin,
          },
          updated_by_id: 1,
          created_by_id: 1,
        )
        next
      end

      # update tags
      if key == 'ticket.tags'
        next if value['value'].empty?
        tags = value['value'].split(/,/)
        if value['operator'] == 'add'
          tags.each { |tag|
            Tag.tag_add(
              object: 'Ticket',
              o_id: id,
              item: tag,
            )
          }
        elsif value['operator'] == 'remove'
          tags.each { |tag|
            Tag.tag_remove(
              object: 'Ticket',
              o_id: id,
              item: tag,
            )
          }
        else
          logger.error "Unknown #{attribute} operator #{value['operator']}"
        end
        next
      end

      # update ticket
      next if self[attribute].to_s == value['value'].to_s
      changed = true

      self[attribute] = value['value']
      logger.debug "set #{object_name}.#{attribute} = #{value['value'].inspect}"
    end
    return if !changed
    save
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
    Ticket::Article.select('in_reply_to, message_id').where(ticket_id: id).each { |article|
      if !article.in_reply_to.empty?
        references.push article.in_reply_to
      end
      next if !article.message_id
      next if article.message_id.empty?
      references.push article.message_id
    }
    ignore.each { |item|
      references.delete(item)
    }
    references
  end

=begin

get all articles of a ticket in correct order (overwrite active record default method)

  artilces = ticket.articles

result

  [article1, articl2]

=end

  def articles
    Ticket::Article.where(ticket_id: id).order(:created_at, :id)
  end

  def history_get(fulldata = false)
    list = History.list(self.class.name, self['id'], 'Ticket::Article')
    return list if !fulldata

    # get related objects
    assets = {}
    list.each { |item|
      record = Kernel.const_get(item['object']).find(item['o_id'])
      assets = record.assets(assets)

      if item['related_object']
        record = Kernel.const_get(item['related_object']).find( item['related_o_id'])
        assets = record.assets(assets)
      end
    }
    {
      history: list,
      assets: assets,
    }
  end

  private

  def check_generate
    return if number
    self.number = Ticket::Number.generate
  end

  def check_title
    return if !title
    title.gsub!(/\s|\t|\r/, ' ')
  end

  def check_defaults
    if !owner_id
      self.owner_id = 1
    end

    return if !customer_id

    customer = User.find_by(id: customer_id)
    return if !customer
    return if organization_id == customer.organization_id

    self.organization_id = customer.organization_id
  end

  def reset_pending_time

    # ignore if no state has changed
    return if !changes['state_id']

    # check if new state isn't pending*
    current_state      = Ticket::State.lookup(id: state_id)
    current_state_type = Ticket::StateType.lookup(id: current_state.state_type_id)

    # in case, set pending_time to nil
    return if current_state_type.name =~ /^pending/i

    self.pending_time = nil
  end

  def check_escalation_update
    escalation_calculation_int
    true
  end

  def destroy_dependencies

    # delete articles
    articles.destroy_all

    # destroy online notifications
    OnlineNotification.remove(self.class.to_s, id)
  end

  def set_default_state
    return if state_id

    default_ticket_state = Ticket::State.find_by(default_create: true)
    return if !default_ticket_state

    self.state_id = default_ticket_state.id
  end

  def set_default_priority
    return if priority_id

    default_ticket_priority = Ticket::Priority.find_by(default_create: true)
    return if !default_ticket_priority

    self.priority_id = default_ticket_priority.id
  end
end
