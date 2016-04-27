# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Transaction::ClearbitEnrichment

=begin
  {
    object: 'User',
    type: 'create',
    object_id: 123,
    changes: {
      'attribute1' => [before, now],
      'attribute2' => [before, now],
    }
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

    return if @item[:object] != 'User'
    return if @item[:type] != 'create'

    return if !Setting.get('clearbit_integration')

    config = Setting.get('clearbit_config')
    return if !config
    return if config['api_key'].empty?

    user = User.lookup(id: @item[:object_id])
    return if !user

    Transaction::ClearbitEnrichment.sync_user(user)
  end

  def self.sync
    users = User.of_role('Customer')
    users.each {|user|
      sync_user(user)
    }
  end

  def self.sync_user(user)
    UserInfo.current_user_id = 1

    return if user.email.empty?
    data = fetch(user.email)
    #p 'OO: ' + data.inspect
    return if !data

    config = Setting.get('clearbit_config')
    return if !config

    # get new user sync attributes
    user_sync = config['user_sync']
    user_sync_values = {}
    if user_sync
      user_sync.each {|callback, destination|
        next if !user_sync_values[destination].empty?
        value = _replace(callback, data)
        next if !value
        user_sync_values[destination] = value
      }
    end

    # get new organization sync attributes
    organization_sync = config['organization_sync']
    organization_sync_values = {}
    if organization_sync
      organization_sync.each {|callback, destination|
        next if !organization_sync_values[destination].empty?
        value = _replace(callback, data)
        next if !value
        organization_sync_values[destination] = value
      }
    end

    # get latest user synced attributes
    external_syn_user = nil
    user_sync_values_last_time = {}
    if data && data['person'] && data['person']['id']
      external_syn_user = ExternalSync.find_by(
        source: 'clearbit',
        source_id: data['person']['id'],
        object: 'User',
        o_id: user.id,
      )
      if external_syn_user && external_syn_user.last_payload
        user_sync.each {|callback, destination|
          next if !user_sync_values_last_time[destination].empty?
          value = _replace(callback, external_syn_user.last_payload)
          next if !value
          user_sync_values_last_time[destination] = value
        }
      end
    end

    # if person record exists
    user_has_changed = false
    user_sync_values.each {|destination, value|
      attribute = destination.sub(/^user\./, '')
      next if user[attribute] == value
      next if !user[attribute].empty? && user_sync_values_last_time[destination] != user[attribute]
      begin
        user[attribute] = value
      rescue => e
        Rails.logger.error "ERROR: Unable to assign user.#{attribute}: #{e.inspect}"
      end
      user_has_changed = true
    }
    if user_has_changed
      user.updated_by_id = 1
      if data['person'] && data['person']['id']
        if external_syn_user
          external_syn_user.last_payload = data
          external_syn_user.save
        else
          external_syn_user = ExternalSync.create(
            source: 'clearbit',
            source_id: data['person']['id'],
            object: 'User',
            o_id: user.id,
            last_payload: data,
          )
        end
      end
    end

    # if no company record exists or no organization should be created
    if !data['company'] || config['organization_autocreate'] != true
      if user_has_changed
        user.save
      end
      Observer::Transaction.commit
      return
    end

    # if company record exists
    external_syn_organization = ExternalSync.find_by(
      source: 'clearbit',
      source_id: data['company']['id'],
    )

    # create new organization
    if !external_syn_organization

      # if organization is already assigned, do not create a new one
      if user.organization_id
        if user_has_changed
          user.save
          Observer::Transaction.commit
        end
        return
      end

      # can't create organization without name
      if organization_sync_values['organization.name'].empty?
        Observer::Transaction.commit
        return
      end

      # find by name
      organization = Organization.find_by(name: organization_sync_values['organization.name'])

      # create new organization
      if !organization
        organization = Organization.new(
          shared: config['organization_shared'],
        )
        organization_sync_values.each {|destination, value|
          attribute = destination.sub(/^organization\./, '')
          next if !organization[attribute].empty?
          begin
            organization[attribute] = value
          rescue => e
            Rails.logger.error "ERROR: Unable to assign organization.#{attribute}: #{e.inspect}"
          end
        }
        organization.save
      end
      ExternalSync.create(
        source: 'clearbit',
        source_id: data['company']['id'],
        object: 'Organization',
        o_id: organization.id,
        last_payload: data,
      )

      # assign new organization to user
      if !user.organization_id
        user.organization_id = organization.id
        user.save
      end
      Observer::Transaction.commit
      return
    end

    # get latest organization synced attributes
    organization_sync_values_last_time = {}
    if external_syn_organization && external_syn_organization.last_payload
      organization_sync.each {|callback, destination|
        next if !organization_sync_values_last_time[destination].empty?
        value = _replace(callback, external_syn_organization.last_payload)
        next if !value
        organization_sync_values_last_time[destination] = value
      }
    end

    # update existing organization
    organization = Organization.find(external_syn_organization[:o_id])
    organization_has_changed = false
    organization_sync_values.each {|destination, value|
      attribute = destination.sub(/^organization\./, '')
      next if organization[attribute] == value
      next if !organization[attribute].empty? && organization_sync_values_last_time[destination] != organization[attribute]
      begin
        organization[attribute] = value
      rescue => e
        Rails.logger.error "ERROR: Unable to assign organization.#{attribute}: #{e.inspect}"
      end
      organization_has_changed = true
    }
    if organization_has_changed
      organization.updated_by_id = 1
      organization.save
      external_syn_organization.last_payload = data
      external_syn_organization.save
    end

    # assign new organization to user
    if !user.organization_id
      user_has_changed = true
      user.organization_id = organization.id
    end

    if user_has_changed
      user.save
    end

    Observer::Transaction.commit
    true
  end

  def self._replace(callback, data)
    object_name   = nil
    object_method = nil
    placeholder   = nil

    if callback =~ /\A ( [\w]+ )\.( [\w\.]+ ) \z/x
      object_name   = $1
      object_method = $2
    end

    return if !data
    return if !data[object_name]

    # do validaton, ignore some methodes
    if callback =~ /(`|\.(|\s*)(save|destroy|delete|remove|drop|update\(|update_att|create\(|new|all|where|find))/i
      placeholder = "#{callback} (not allowed)"

    # get value based on object_name and object_method
    elsif object_name && object_method
      object_refs      = data[object_name]
      object_methods   = object_method.split('.')
      object_methods_s = ''
      object_methods.each {|method|
        if object_methods_s != ''
          object_methods_s += '.'
        end
        object_methods_s += method

        # if method exists
        break if !object_refs.respond_to?(method.to_sym) && !object_refs[method]

        object_refs = if object_refs.respond_to?(method.to_sym)
                        object_refs.send(method.to_sym)
                      else
                        object_refs[method]
                      end
      }
      if object_refs.class == String
        placeholder = object_refs
      end
    end
    placeholder
  end

  def self.fetch(email)
    if !Rails.env.production?
      filename = "#{Rails.root}/test/fixtures/clearbit/#{email}.json"
      if File.exist?(filename)
        data = IO.binread(filename)
        return JSON.parse(data) if data
      end
    end

    config = Setting.get('clearbit_config')
    return if !config
    return if config['api_key'].empty?

    record = {
      direction: 'out',
      facility: 'clearbit',
      url: "clearbit -> #{email}",
      status: 200,
      ip: nil,
      request: { content: email },
      response: {},
      method: 'GET',
    }

    begin
      Clearbit.key = config['api_key']
      result = Clearbit::Enrichment.find(email: email, stream: true)
      record[:response] = { code: 200, content: result.to_s }
    rescue => e
      record[:status] = 500
      record[:response] = { code: 500, content: e.inspect }
    end
    HttpLog.create(record)
    result
  end

end
