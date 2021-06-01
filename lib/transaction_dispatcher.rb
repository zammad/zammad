# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TransactionDispatcher

  def self.reset
    EventBuffer.reset('transaction')
  end

  def self.commit(params = {})

    # add attribute of interface handle (e. g. to send (no) notifications if a agent
    # is creating a ticket via application_server, but send it if it's created via
    # postmaster)
    params[:interface_handle] = ApplicationHandleInfo.current

    # execute object transactions
    TransactionDispatcher.perform(params)
  end

  def self.perform(params)

    # return if we run import mode
    return if Setting.get('import_mode')

    # get buffer
    list = EventBuffer.list('transaction')

    # reset buffer
    EventBuffer.reset('transaction')

    # get async backends
    sync_backends = []
    Setting.where(area: 'Transaction::Backend::Sync').order(:name).each do |setting|
      backend = Setting.get(setting.name)
      next if params[:disable]&.include?(backend)

      sync_backends.push backend.constantize
    end

    # get uniq objects
    list_objects = get_uniq_changes(list)
    list_objects.each_value do |objects|
      objects.each_value do |item|

        # execute sync backends
        sync_backends.each do |backend|
          execute_single_backend(backend, item, params)
        end

        # execute async backends
        TransactionJob.perform_later(item, params)
      end
    end
  end

  def self.execute_single_backend(backend, item, params)
    Rails.logger.debug { "Execute single backend #{backend}" }
    begin
      UserInfo.current_user_id = nil
      integration = backend.new(item, params)
      integration.perform
    rescue => e
      Rails.logger.error e
    end
  end

=begin

  result = get_uniq_changes(events)

  result = {
    'Ticket' =>
      1 => {
        object: 'Ticket',
        type: 'create',
        object_id: 123,
        article_id: 123,
        user_id: 123,
        created_at: Time.zone.now,
      },
      9 => {
        object: 'Ticket',
        type: 'update',
        object_id: 123,
        changes: {
          attribute1: [before, now],
          attribute2: [before, now],
        },
        user_id: 123,
        created_at: Time.zone.now,
      },
    },
  }

  result = {
    'Ticket' =>
      9 => {
        object: 'Ticket',
        type: 'update',
        object_id: 123,
        article_id: 123,
        changes: {
          attribute1: [before, now],
          attribute2: [before, now],
        },
        user_id: 123,
        created_at: Time.zone.now,
      },
    },
  }

=end

  def self.get_uniq_changes(events)
    list_objects = {}
    events.each do |event|

      # simulate article create as ticket update
      article = nil
      if event[:object] == 'Ticket::Article'
        article = Ticket::Article.find_by(id: event[:id])
        next if !article
        next if event[:type] == 'update'

        # set new event infos
        ticket = Ticket.find_by(id: article.ticket_id)
        event[:object] = 'Ticket'
        event[:id] = ticket.id
        event[:type] = 'update'
        event[:changes] = nil
      end

      # get current state of objects
      object = event[:object].constantize.find_by(id: event[:id])

      # next if object is already deleted
      next if !object

      if !list_objects[event[:object]]
        list_objects[event[:object]] = {}
      end
      if !list_objects[event[:object]][object.id]
        list_objects[event[:object]][object.id] = {}
      end
      store = list_objects[event[:object]][object.id]
      store[:object] = event[:object]
      store[:object_id] = object.id
      store[:user_id] = event[:user_id]
      store[:created_at] = event[:created_at]

      if !store[:type] || store[:type] == 'update'
        store[:type] = event[:type]
      end

      # merge changes
      if event[:changes]
        if store[:changes]
          event[:changes].each do |key, value|
            if store[:changes][key]
              store[:changes][key][1] = value[1]
            else
              store[:changes][key] = value
            end
          end
        else
          store[:changes] = event[:changes]
        end
      end

      # remember article id if exists
      if article
        store[:article_id] = article.id
      end
    end
    list_objects
  end

  # Used as ActiveRecord lifecycle callback on the class.
  def self.after_create(record)

    # return if we run import mode
    return true if Setting.get('import_mode')

    e = {
      object:     record.class.name,
      type:       'create',
      data:       record,
      id:         record.id,
      user_id:    record.created_by_id,
      created_at: Time.zone.now,
    }
    EventBuffer.add('transaction', e)
    true
  end

  # Used as ActiveRecord lifecycle callback on the class.
  def self.before_update(record)

    # return if we run import mode
    return true if Setting.get('import_mode')

    # ignore certain attributes
    real_changes = {}
    record.changes_to_save.each do |key, value|
      next if key == 'updated_at'
      next if key == 'first_response_at'
      next if key == 'close_at'
      next if key == 'last_contact_agent_at'
      next if key == 'last_contact_customer_at'
      next if key == 'last_contact_at'
      next if key == 'article_count'
      next if key == 'create_article_type_id'
      next if key == 'create_article_sender_id'

      real_changes[key] = value
    end

    # do not send anything if nothing has changed
    return true if real_changes.blank?

    changed_by_id = if record.respond_to?('updated_by_id')
                      record.updated_by_id
                    else
                      record.created_by_id
                    end

    e = {
      object:     record.class.name,
      type:       'update',
      data:       record,
      changes:    real_changes,
      id:         record.id,
      user_id:    changed_by_id,
      created_at: Time.zone.now,
    }
    EventBuffer.add('transaction', e)
    true
  end

end
