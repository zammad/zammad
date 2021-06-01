# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Transaction::Notification

=begin
  {
    object: 'Ticket',
    type: 'update',
    object_id: 123,
    interface_handle: 'application_server', # application_server|websocket|scheduler
    changes: {
      'attribute1' => [before, now],
      'attribute2' => [before, now],
    },
    created_at: Time.zone.now,
    user_id: 123,
  },
=end

  def initialize(item, params = {})
    @item = item
    @params = params
  end

  def perform

    # return if we run import mode
    return if Setting.get('import_mode')
    return if @item[:object] != 'Ticket'
    return if @params[:disable_notification]

    ticket = Ticket.find_by(id: @item[:object_id])
    return if !ticket

    if @item[:article_id]
      article = Ticket::Article.find(@item[:article_id])

      # ignore notifications
      sender = Ticket::Article::Sender.lookup(id: article.sender_id)
      if sender&.name == 'System'
        return if @item[:changes].blank? && article.preferences[:notification] != true

        if article.preferences[:notification] != true
          article = nil
        end
      end
    end

    # find recipients
    recipients_and_channels = []
    recipients_reason = {}

    # loop through all group users
    possible_recipients = possible_recipients_of_group(ticket.group_id)

    # loop through all mention users
    mention_users = Mention.where(mentionable_type: @item[:object], mentionable_id: @item[:object_id]).map(&:user)
    if mention_users.present?

      # only notify if read permission on group are given
      mention_users.each do |mention_user|
        next if !mention_user.group_access?(ticket.group_id, 'read')

        possible_recipients.push mention_user
        recipients_reason[mention_user.id] = 'are subscribed'
      end
    end

    # apply owner
    if ticket.owner_id != 1
      possible_recipients.push ticket.owner
      recipients_reason[ticket.owner_id] = 'are assigned'
    end

    # apply out of office agents
    possible_recipients_additions = Set.new
    possible_recipients.each do |user|
      recursive_ooo_replacements(
        user:         user,
        replacements: possible_recipients_additions,
        reasons:      recipients_reason,
      )
    end

    if possible_recipients_additions.present?
      # join unique entries
      possible_recipients = possible_recipients | possible_recipients_additions.to_a
    end

    already_checked_recipient_ids = {}
    possible_recipients.each do |user|
      result = NotificationFactory::Mailer.notification_settings(user, ticket, @item[:type])
      next if !result
      next if already_checked_recipient_ids[user.id]

      already_checked_recipient_ids[user.id] = true
      recipients_and_channels.push result
      next if recipients_reason[user.id]

      recipients_reason[user.id] = 'are in group'
    end

    # send notifications
    recipients_and_channels.each do |item|
      user = item[:user]
      channels = item[:channels]

      # ignore user who changed it by him self via web
      if @params[:interface_handle] == 'application_server'
        next if article&.updated_by_id == user.id
        next if !article && @item[:user_id] == user.id
      end

      # ignore inactive users
      next if !user.active?

      # ignore if no changes has been done
      changes = human_changes(user, ticket)
      next if @item[:type] == 'update' && !article && changes.blank?

      # check if today already notified
      if @item[:type] == 'reminder_reached' || @item[:type] == 'escalation' || @item[:type] == 'escalation_warning'
        identifier = user.email
        if !identifier || identifier == ''
          identifier = user.login
        end

        already_notified = History.where(
          history_type_id:   History.type_lookup('notification').id,
          history_object_id: History.object_lookup('Ticket').id,
          o_id:              ticket.id
        ).where('created_at > ?', Time.zone.now.beginning_of_day).exists?(['value_to LIKE ?', "%#{identifier}(#{@item[:type]}:%"])

        next if already_notified
      end

      # create online notification
      used_channels = []
      if channels['online']
        used_channels.push 'online'

        created_by_id = @item[:user_id] || 1

        # delete old notifications
        if @item[:type] == 'reminder_reached'
          seen = false
          created_by_id = 1
          OnlineNotification.remove_by_type('Ticket', ticket.id, @item[:type], user)

        elsif @item[:type] == 'escalation' || @item[:type] == 'escalation_warning'
          seen = false
          created_by_id = 1
          OnlineNotification.remove_by_type('Ticket', ticket.id, 'escalation', user)
          OnlineNotification.remove_by_type('Ticket', ticket.id, 'escalation_warning', user)

        # on updates without state changes create unseen messages
        elsif @item[:type] != 'create' && (@item[:changes].blank? || @item[:changes]['state_id'].blank?)
          seen = false
        else
          seen = ticket.online_notification_seen_state(user.id)
        end

        OnlineNotification.add(
          type:          @item[:type],
          object:        'Ticket',
          o_id:          ticket.id,
          seen:          seen,
          created_by_id: created_by_id,
          user_id:       user.id,
        )
        Rails.logger.debug { "sent ticket online notifiaction to agent (#{@item[:type]}/#{ticket.id}/#{user.email})" }
      end

      # ignore email channel notification and empty emails
      if !channels['email'] || user.email.blank?
        add_recipient_list(ticket, user, used_channels, @item[:type])
        next
      end

      used_channels.push 'email'
      add_recipient_list(ticket, user, used_channels, @item[:type])

      # get user based notification template
      # if create, send create message / block update messages
      template = nil
      case @item[:type]
      when 'create'
        template = 'ticket_create'
      when 'update'
        template = 'ticket_update'
      when 'reminder_reached'
        template = 'ticket_reminder_reached'
      when 'escalation'
        template = 'ticket_escalation'
      when 'escalation_warning'
        template = 'ticket_escalation_warning'
      else
        raise "unknown type for notification #{@item[:type]}"
      end

      current_user = User.lookup(id: @item[:user_id])
      if !current_user
        current_user = User.lookup(id: 1)
      end

      attachments = []
      if article
        attachments = article.attachments_inline
      end
      NotificationFactory::Mailer.notification(
        template:    template,
        user:        user,
        objects:     {
          ticket:       ticket,
          article:      article,
          recipient:    user,
          current_user: current_user,
          changes:      changes,
          reason:       recipients_reason[user.id],
        },
        message_id:  "<notification.#{DateTime.current.to_s(:number)}.#{ticket.id}.#{user.id}.#{rand(999_999)}@#{Setting.get('fqdn')}>",
        references:  ticket.get_references,
        main_object: ticket,
        attachments: attachments,
      )
      Rails.logger.debug { "sent ticket email notifiaction to agent (#{@item[:type]}/#{ticket.id}/#{user.email})" }
    end

  end

  def add_recipient_list(ticket, user, channels, type)
    return if channels.blank?

    identifier = user.email
    if !identifier || identifier == ''
      identifier = user.login
    end
    recipient_list = "#{identifier}(#{type}:#{channels.join(',')})"
    History.add(
      o_id:           ticket.id,
      history_type:   'notification',
      history_object: 'Ticket',
      value_to:       recipient_list,
      created_by_id:  @item[:user_id] || 1
    )
  end

  def human_changes(user, record)

    return {} if !@item[:changes]

    locale = user.locale

    # only show allowed attributes
    attribute_list = ObjectManager::Object.new('Ticket').attributes(user).index_by { |item| item[:name] }

    user_related_changes = {}
    @item[:changes].each do |key, value|

      # if no config exists, use all attributes
      # or if config exists, just use existing attributes for user
      if attribute_list.blank? || attribute_list[key.to_s]
        user_related_changes[key] = value
      end
    end

    changes = {}
    user_related_changes.each do |key, value|

      # get attribute name
      attribute_name           = key.to_s
      object_manager_attribute = attribute_list[attribute_name]
      if attribute_name[-3, 3] == '_id'
        attribute_name = attribute_name[ 0, attribute_name.length - 3 ].to_s
      end

      # add item to changes hash
      if key.to_s == attribute_name
        changes[attribute_name] = value
      end

      # if changed item is an _id field/reference, look up the real values
      value_id  = []
      value_str = [ value[0], value[1] ]
      if key.to_s[-3, 3] == '_id'
        value_id[0] = value[0]
        value_id[1] = value[1]

        if record.respond_to?(attribute_name) && record.send(attribute_name)
          relation_class = record.send(attribute_name).class
          if relation_class && value_id[0]
            relation_model = relation_class.lookup(id: value_id[0])
            if relation_model
              if relation_model['name']
                value_str[0] = relation_model['name']
              elsif relation_model.respond_to?('fullname')
                value_str[0] = relation_model.send('fullname')
              end
            end
          end
          if relation_class && value_id[1]
            relation_model = relation_class.lookup(id: value_id[1])
            if relation_model
              if relation_model['name']
                value_str[1] = relation_model['name']
              elsif relation_model.respond_to?('fullname')
                value_str[1] = relation_model.send('fullname')
              end
            end
          end
        end
      end

      # check if we have a dedicated display name for it
      display = attribute_name
      if object_manager_attribute && object_manager_attribute[:display]

        # delete old key
        changes.delete(display)

        # set new key
        display = object_manager_attribute[:display].to_s
      end
      changes[display] = if object_manager_attribute && object_manager_attribute[:translate]
                           from = Translation.translate(locale, value_str[0])
                           to = Translation.translate(locale, value_str[1])
                           [from, to]
                         else
                           [value_str[0].to_s, value_str[1].to_s]
                         end
    end
    changes
  end

  private

  def recursive_ooo_replacements(user:, replacements:, reasons:, level: 0)
    if level == 10
      Rails.logger.warn("Found more than 10 replacement levels for agent #{user}.")
      return
    end

    replacement = user.out_of_office_agent
    return if !replacement
    # return for already found, added and checked users
    # to prevent re-doing complete lookup paths
    return if !replacements.add?(replacement)

    reasons[replacement.id] = 'are the out-of-office replacement of the owner'

    recursive_ooo_replacements(
      user:         replacement,
      replacements: replacements,
      reasons:      reasons,
      level:        level + 1
    )
  end

  def possible_recipients_of_group(group_id)
    cache = Cache.read("Transaction::Notification.group_access.full::#{group_id}")
    return cache if cache

    possible_recipients = User.group_access(group_id, 'full').sort_by(&:login)
    Cache.write("Transaction::Notification.group_access.full::#{group_id}", possible_recipients, expires_in: 20.seconds)
    possible_recipients
  end
end
