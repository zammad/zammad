# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class ApplicationModel < ActiveRecord::Base
  include ApplicationModel::Assets
  include ApplicationModel::HistoryLogBase
  include ApplicationModel::ActivityStreamBase
  include ApplicationModel::SearchIndexBase

  self.abstract_class = true

  before_create  :check_attributes_protected, :check_limits, :cache_delete, :fill_up_user_create
  before_update  :check_limits, :fill_up_user_update
  before_destroy :destroy_dependencies

  after_create  :cache_delete
  after_update  :cache_delete
  after_touch   :cache_delete
  after_destroy :cache_delete

  after_create  :attachments_buffer_check
  after_update  :attachments_buffer_check

  after_create  :activity_stream_create
  after_update  :activity_stream_update
  before_destroy :activity_stream_destroy

  after_create  :history_create
  after_update  :history_update
  after_destroy :history_destroy

  after_create  :search_index_update
  after_update  :search_index_update
  after_destroy :search_index_destroy

  before_destroy :recent_view_destroy

  # create instance accessor
  class << self
    attr_accessor :activity_stream_support_config, :history_support_config, :search_index_support_config
  end

  attr_accessor :history_changes_last_done

  def check_attributes_protected

    import_class_list = ['Ticket', 'Ticket::Article', 'History', 'Ticket::State', 'Ticket::StateType', 'Ticket::Priority', 'Group', 'User', 'Role' ]

    # do noting, use id as it is
    return if !Setting.get('system_init_done')
    return if Setting.get('import_mode') && import_class_list.include?( self.class.to_s )

    self[:id] = nil
  end

=begin

remove all not used model attributes of params

  result = Model.param_cleanup(params)

  for object creation, ignore id's

  result = Model.param_cleanup(params, true)

returns

  result = params # params with valid attributes of model

=end

  def self.param_cleanup(params, newObject = false)

    if params.nil?
      fail "No params for #{self}!"
    end

    # ignore id for new objects
    if newObject && params[:id]
      params[:id] = nil
    end

    # only use object attributes
    data = {}
    new.attributes.each {|item|
      next if !params.key?(item[0])
      data[item[0].to_sym] = params[item[0]]
    }

    # we do want to set this via database
    param_validation(data)
  end

=begin

set rellations of model based on params

  model = Model.find(1)
  result = model.param_set_associations(params)

returns

  result = true|false

=end

  def param_set_associations(params)

    # set relations
    self.class.reflect_on_all_associations.map { |assoc|
      real_key = assoc.name.to_s[0, assoc.name.to_s.length - 1] + '_ids'

      next if !params.key?(real_key.to_sym)

      list_of_items = params[ real_key.to_sym ]
      if params[ real_key.to_sym ].class != Array
        list_of_items = [ params[ real_key.to_sym ] ]
      end
      list = []
      list_of_items.each {|item|
        list.push(assoc.klass.find(item))
      }
      send(assoc.name.to_s + '=', list)
    }
  end

=begin

get rellations of model based on params

  model = Model.find(1)
  attributes = model.attributes_with_associations

returns

  hash with attributes and association ids

=end

  def attributes_with_associations

    # set relations
    attributes = self.attributes
    self.class.reflect_on_all_associations.map { |assoc|
      real_key = assoc.name.to_s[0, assoc.name.to_s.length - 1] + '_ids'
      if respond_to?(real_key)
        attributes[ real_key ] = send(real_key)
      end
    }
    attributes
  end

=begin

remove all not used params of object (per default :updated_at, :created_at, :updated_by_id and :created_by_id)

  result = Model.param_validation(params)

returns

  result = params # params without listed attributes

=end

  def self.param_validation(data)

    # we do want to set this via database
    data.delete(:updated_at)
    data.delete(:created_at)
    data.delete(:updated_by_id)
    data.delete(:created_by_id)
    if data.respond_to?('permit!')
      data.permit!
    end
    data
  end

=begin

set created_by_id & updated_by_id if not given based on UserInfo (current session)

Used as before_create callback, no own use needed

  result = Model.fill_up_user_create(params)

returns

  result = params # params with updated_by_id & created_by_id if not given based on UserInfo (current session)

=end

  def fill_up_user_create
    if self.class.column_names.include? 'updated_by_id'
      if UserInfo.current_user_id
        if updated_by_id && updated_by_id != UserInfo.current_user_id
          logger.info "NOTICE create - self.updated_by_id is different: #{updated_by_id}/#{UserInfo.current_user_id}"
        end
        self.updated_by_id = UserInfo.current_user_id
      end
    end

    return if !self.class.column_names.include? 'created_by_id'

    return if !UserInfo.current_user_id

    if created_by_id && created_by_id != UserInfo.current_user_id
      logger.info "NOTICE create - self.created_by_id is different: #{created_by_id}/#{UserInfo.current_user_id}"
    end
    self.created_by_id = UserInfo.current_user_id
  end

=begin

set updated_by_id if not given based on UserInfo (current session)

Used as before_update callback, no own use needed

  result = Model.fill_up_user_update(params)

returns

  result = params # params with updated_by_id & created_by_id if not given based on UserInfo (current session)

=end

  def fill_up_user_update
    return if !self.class.column_names.include? 'updated_by_id'
    return if !UserInfo.current_user_id

    self.updated_by_id = UserInfo.current_user_id
  end

  def cache_update(o)
    cache_delete if respond_to?('cache_delete')
    o.cache_delete if o.respond_to?('cache_delete')
  end

  def cache_delete

    # delete id caches
    key = "#{self.class}::#{id}"
    Cache.delete(key)

    # delete old name / login caches
    if changed?
      if changes.key?('name')
        name = changes['name'][0]
        key = "#{self.class}::#{name}"
        Cache.delete(key.to_s)
      end
      if changes.key?('login')
        name = changes['login'][0]
        key = "#{self.class}::#{name}"
        Cache.delete(key)
      end
    end

    # delete name caches
    if self[:name]
      key = "#{self.class}::#{self.name}"
      Cache.delete(key)
    end

    # delete login caches
    return if !self[:login]

    Cache.delete("#{self.class}::#{login}")
  end

  def self.cache_set(data_id, data)
    key = "#{self}::#{data_id}"
    Cache.write(key, data)
  end

  def self.cache_get(data_id)
    key = "#{self}::#{data_id}"
    Cache.get(key)
  end

=begin

generate uniq name (will check name of model and generates _1 sequenze)

Used as before_update callback, no own use needed

  name = Model.genrate_uniq_name('some name')

returns

  result = 'some name_X'

=end

  def self.genrate_uniq_name(name)
    return name if !find_by(name: name)
    (1..100).each {|counter|
      name = "#{name}_#{counter}"
      exists = find_by(name: name)
      next if exists
      break
    }
    name
  end

=begin

lookup model from cache (if exists) or retrieve it from db, id, name or login possible

  result = Model.lookup(id: 123)
  result = Model.lookup(name: 'some name')
  result = Model.lookup(login: 'some login')

returns

  result = model # with all attributes

=end

  def self.lookup(data)
    if data[:id]
      cache = cache_get(data[:id])
      return cache if cache

      record = find_by(id: data[:id])
      cache_set(data[:id], record)
      return record
    elsif data[:name]
      cache = cache_get(data[:name])
      return cache if cache

      # do lookup with == to handle case insensitive databases
      records = where(name: data[:name])
      records.each {|loop_record|
        if loop_record.name == data[:name]
          cache_set(data[:name], loop_record)
          return loop_record
        end
      }
      return
    elsif data[:login]
      cache = cache_get(data[:login])
      return cache if cache

      # do lookup with == to handle case insensitive databases
      records = where(login: data[:login])
      records.each {|loop_record|
        if loop_record.login == data[:login]
          cache_set( data[:login], loop_record)
          return loop_record
        end
      }
      return
    end

    fail 'Need name, id or login for lookup()'
  end

=begin

create model if not exists (check exists based on id, name, login, email or locale)

  result = Model.create_if_not_exists(attributes)

returns

  result = model # with all attributes

=end

  def self.create_if_not_exists(data)
    if data[:id]
      record = find_by(id: data[:id])
      return record if record
    elsif data[:name]

      # do lookup with == to handle case insensitive databases
      records = where(name: data[:name])
      records.each {|loop_record|
        return loop_record if loop_record.name == data[:name]
      }
    elsif data[:login]

      # do lookup with == to handle case insensitive databases
      records = where(login: data[:login])
      records.each {|loop_record|
        return loop_record if loop_record.login == data[:login]
      }
    elsif data[:email]

      # do lookup with == to handle case insensitive databases
      records = where(email: data[:email])
      records.each {|loop_record|
        return loop_record if loop_record.email == data[:email]
      }
    elsif data[:locale] && data[:source]

      # do lookup with == to handle case insensitive databases
      records = where(locale: data[:locale], source: data[:source])
      records.each {|loop_record|
        return loop_record if loop_record.source == data[:source]
      }
    end
    create(data)
  end

=begin

create or update model (check exists based on id, name, login, email or locale)

  result = Model.create_or_update(attributes)

returns

  result = model # with all attributes

=end

  def self.create_or_update(data)
    if data[:id]
      record = find_by(id: data[:id])
      if record
        record.update_attributes(data)
        return record
      end
      record = new(data)
      record.save
      return record
    elsif data[:name]

      # do lookup with == to handle case insensitive databases
      records = where(name: data[:name])
      records.each {|loop_record|
        if loop_record.name == data[:name]
          loop_record.update_attributes(data)
          return loop_record
        end
      }
      record = new(data)
      record.save
      return record
    elsif data[:login]

      # do lookup with == to handle case insensitive databases
      records = where(login: data[:login])
      records.each {|loop_record|
        if loop_record.login.casecmp(data[:login]).zero?
          loop_record.update_attributes(data)
          return loop_record
        end
      }
      record = new(data)
      record.save
      return record
    elsif data[:email]

      # do lookup with == to handle case insensitive databases
      records = where(email: data[:email])
      records.each {|loop_record|
        if loop_record.email.casecmp(data[:email]).zero?
          loop_record.update_attributes(data)
          return loop_record
        end
      }
      record = new(data)
      record.save
      return record
    elsif data[:locale]

      # do lookup with == to handle case insensitive databases
      records = where(locale: data[:locale])
      records.each {|loop_record|
        if loop_record.locale.casecmp(data[:locale]).zero?
          loop_record.update_attributes(data)
          return loop_record
        end
      }
      record = new(data)
      record.save
      return record
    else
      fail 'Need name, login, email or locale for create_or_update()'
    end
  end

=begin

activate latest change on create, update, touch and destroy

class Model < ApplicationModel
  latest_change_support
end

=end

  def self.latest_change_support
    after_create  :latest_change_set_from_observer
    after_update  :latest_change_set_from_observer
    after_touch   :latest_change_set_from_observer
    after_destroy :latest_change_set_from_observer_destroy
  end

  def latest_change_set_from_observer
    self.class.latest_change_set(updated_at)
  end

  def latest_change_set_from_observer_destroy
    self.class.latest_change_set(nil)
  end

  def self.latest_change_set(updated_at)
    key        = "#{new.class.name}_latest_change"
    expires_in = 31_536_000 # 1 year

    if updated_at.nil?
      Cache.delete(key)
    else
      Cache.write(key, updated_at, { expires_in: expires_in })
    end
  end

=begin

  get latest updated_at object timestamp

  latest_change = Ticket.latest_change

returns

  result = timestamp

=end

  def self.latest_change
    key        = "#{new.class.name}_latest_change"
    updated_at = Cache.get( key )

    # if we do not have it cached, do lookup
    if !updated_at
      o = select(:updated_at).order(updated_at: :desc).limit(1).first
      if o
        updated_at = o.updated_at
        latest_change_set(updated_at)
      end
    end
    updated_at
  end

=begin

activate client notify support on create, update, touch and destroy

class Model < ApplicationModel
  notify_clients_support
end

=end

  def self.notify_clients_support
    after_create  :notify_clients_after_create
    after_update  :notify_clients_after_update
    after_touch   :notify_clients_after_touch
    after_destroy :notify_clients_after_destroy
  end

=begin

notify_clients_after_create after model got created

used as callback in model file

class OwnModel < ApplicationModel
  after_create    :notify_clients_after_create
  after_update    :notify_clients_after_update
  after_touch     :notify_clients_after_touch
  after_destroy   :notify_clients_after_destroy

  [...]

=end

  def notify_clients_after_create

    # return if we run import mode
    return if Setting.get('import_mode')
    logger.debug "#{self.class.name}.find(#{id}) notify created " + created_at.to_s
    class_name = self.class.name
    class_name.gsub!(/::/, '')
    Sessions.broadcast(
      event: class_name + ':create',
      data: { id: id, updated_at: updated_at }
    )
  end

=begin

notify_clients_after_update after model got updated

used as callback in model file

class OwnModel < ApplicationModel
  after_create    :notify_clients_after_create
  after_update    :notify_clients_after_update
  after_touch     :notify_clients_after_touch
  after_destroy   :notify_clients_after_destroy

  [...]

=end

  def notify_clients_after_update

    # return if we run import mode
    return if Setting.get('import_mode')
    logger.debug "#{self.class.name}.find(#{id}) notify UPDATED " + updated_at.to_s
    class_name = self.class.name
    class_name.gsub!(/::/, '')
    Sessions.broadcast(
      event: class_name + ':update',
      data: { id: id, updated_at: updated_at }
    )
  end

=begin

notify_clients_after_touch after model got touched

used as callback in model file

class OwnModel < ApplicationModel
  after_create    :notify_clients_after_create
  after_update    :notify_clients_after_update
  after_touch     :notify_clients_after_touch
  after_destroy   :notify_clients_after_destroy

  [...]

=end

  def notify_clients_after_touch

    # return if we run import mode
    return if Setting.get('import_mode')
    logger.debug "#{self.class.name}.find(#{id}) notify TOUCH " + updated_at.to_s
    class_name = self.class.name
    class_name.gsub!(/::/, '')
    Sessions.broadcast(
      event: class_name + ':touch',
      data: { id: id, updated_at: updated_at }
    )
  end

=begin

notify_clients_after_destroy after model got destroyed

used as callback in model file

class OwnModel < ApplicationModel
  after_create    :notify_clients_after_create
  after_update    :notify_clients_after_update
  after_touch     :notify_clients_after_touch
  after_destroy   :notify_clients_after_destroy

  [...]

=end
  def notify_clients_after_destroy

    # return if we run import mode
    return if Setting.get('import_mode')
    logger.debug "#{self.class.name}.find(#{id}) notify DESTOY " + updated_at.to_s
    class_name = self.class.name
    class_name.gsub!(/::/, '')
    Sessions.broadcast(
      event: class_name + ':destroy',
      data: { id: id, updated_at: updated_at }
    )
  end

=begin

serve methode to configure and enable search index support for this model

class Model < ApplicationModel
  search_index_support ignore_attributes: {
    create_article_type_id:   true,
    create_article_sender_id: true,
    article_count:            true,
  }

end

=end

  def self.search_index_support(data = {})
    @search_index_support_config = data
  end

=begin

update search index, if configured - will be executed automatically

  model = Model.find(123)
  model.search_index_update

=end

  def search_index_update
    return if !self.class.search_index_support_config

    # start background job to transfer data to search index
    return if !SearchIndexBackend.enabled?
    Delayed::Job.enqueue( ApplicationModel::BackgroundJobSearchIndex.new( self.class.to_s, id ) )
  end

=begin

delete search index object, will be executed automatically

  model = Model.find(123)
  model.search_index_destroy

=end

  def search_index_destroy
    return if !self.class.search_index_support_config
    SearchIndexBackend.remove(self.class.to_s, id)
  end

=begin

reload search index with full data

  Model.search_index_reload

=end

  def self.search_index_reload
    return if !@search_index_support_config
    all_ids = select('id').all.order('created_at DESC')
    all_ids.each { |item_with_id|
      item = find( item_with_id.id )
      item.search_index_update_backend
    }
  end

=begin

serve methode to configure and enable activity stream support for this model

class Model < ApplicationModel
  activity_stream_support role: 'Admin'
end

=end

  def self.activity_stream_support(data = {})
    @activity_stream_support_config = data
  end

=begin

log object create activity stream, if configured - will be executed automatically

  model = Model.find(123)
  model.activity_stream_create

=end

  def activity_stream_create
    return if !self.class.activity_stream_support_config
    activity_stream_log('created', self['created_by_id'])
  end

=begin

log object update activity stream, if configured - will be executed automatically

  model = Model.find(123)
  model.activity_stream_update

=end

  def activity_stream_update
    return if !self.class.activity_stream_support_config

    return if !changed?

    # default ignored attributes
    ignore_attributes = {
      created_at: true,
      updated_at: true,
      created_by_id: true,
      updated_by_id: true,
    }
    if self.class.activity_stream_support_config[:ignore_attributes]
      self.class.activity_stream_support_config[:ignore_attributes].each {|key, value|
        ignore_attributes[key] = value
      }
    end

    log = false
    changes.each {|key, _value|

      # do not log created_at and updated_at attributes
      next if ignore_attributes[key.to_sym] == true

      log = true
    }

    return if !log

    activity_stream_log('updated', self['updated_by_id'])
  end

=begin

delete object activity stream, will be executed automatically

  model = Model.find(123)
  model.activity_stream_destroy

=end

  def activity_stream_destroy
    return if !self.class.activity_stream_support_config
    ActivityStream.remove(self.class.to_s, id)
  end

=begin

serve methode to configure and enable history support for this model

class Model < ApplicationModel
  history_support
end

class Model < ApplicationModel
  history_support ignore_attributes: { article_count: true }
end

=end

  def self.history_support(data = {})
    @history_support_config = data
  end

=begin

log object create history, if configured - will be executed automatically

  model = Model.find(123)
  model.history_create

=end

  def history_create
    return if !self.class.history_support_config
    #logger.debug 'create ' + self.changes.inspect
    history_log('created', created_by_id)

  end

=begin

log object update history with all updated attributes, if configured - will be executed automatically

  model = Model.find(123)
  model.history_update

=end

  def history_update
    return if !self.class.history_support_config

    return if !changed?

    # return if it's no update
    return if new_record?

    # new record also triggers update, so ignore new records
    changes = self.changes
    if history_changes_last_done
      history_changes_last_done.each {|key, value|
        if changes.key?(key) && changes[key] == value
          changes.delete(key)
        end
      }
    end
    self.history_changes_last_done = changes
    #logger.info 'updated ' + self.changes.inspect

    return if changes['id'] && !changes['id'][0]

    # default ignored attributes
    ignore_attributes = {
      created_at: true,
      updated_at: true,
      created_by_id: true,
      updated_by_id: true,
    }
    if self.class.history_support_config[:ignore_attributes]
      self.class.history_support_config[:ignore_attributes].each {|key, value|
        ignore_attributes[key] = value
      }
    end

    changes.each {|key, value|

      # do not log created_at and updated_at attributes
      next if ignore_attributes[key.to_sym] == true

      # get attribute name
      attribute_name = key.to_s
      if attribute_name[-3, 3] == '_id'
        attribute_name = attribute_name[ 0, attribute_name.length - 3 ]
      end

      value_id = []
      value_str = [ value[0], value[1] ]
      if key.to_s[-3, 3] == '_id'
        value_id[0] = value[0]
        value_id[1] = value[1]

        if respond_to?( attribute_name ) && send(attribute_name)
          relation_class = send(attribute_name).class
          if relation_class && value_id[0]
            relation_model = relation_class.lookup( id: value_id[0] )
            if relation_model
              if relation_model['name']
                value_str[0] = relation_model['name']
              elsif relation_model.respond_to?('fullname')
                value_str[0] = relation_model.send('fullname')
              end
            end
          end
          if relation_class && value_id[1]
            relation_model = relation_class.lookup( id: value_id[1] )
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
      data = {
        history_attribute: attribute_name,
        value_from: value_str[0].to_s,
        value_to: value_str[1].to_s,
        id_from: value_id[0],
        id_to: value_id[1],
      }
      #logger.info "HIST NEW #{self.class.to_s}.find(#{self.id}) #{data.inspect}"
      history_log('updated', updated_by_id, data)
    }
  end

=begin

delete object history, will be executed automatically

  model = Model.find(123)
  model.history_destroy

=end

  def history_destroy
    return if !self.class.history_support_config
    History.remove(self.class.to_s, id)
  end

=begin

get list of attachments of this object

  item = Model.find(123)
  list = item.attachments

returns

  # array with Store model objects

=end

  def attachments
    Store.list(object: self.class.to_s, o_id: id)
  end

=begin

store attachments for this object

  item = Model.find(123)
  item.attachments = [ Store-Object1, Store-Object2 ]

=end

  def attachments=(attachments)
    self.attachments_buffer = attachments

    # update if object already exists
    return if !( id && id != 0 )

    attachments_buffer_check
  end

=begin

return object and assets

  data = Model.full(123)
  data = {
    id:     123,
    assets: assets,
  }

=end

  def self.full(id)
    object = find(id)
    assets = object.assets({})
    {
      id: id,
      assets: assets,
    }
  end

=begin

get assets of object list

  list = [
    {
      object => 'Ticket',
      o_id   => 1,
    },
    {
      object => 'User',
      o_id   => 121,
    },
  ]

  assets = Model.assets_of_object_list(list, assets)

=end

  def self.assets_of_object_list(list, assets = {})
    list.each {|item|
      require item['object'].to_filename
      record = Kernel.const_get(item['object']).find(item['o_id'])
      assets = record.assets(assets)
      if item['created_by_id']
        user = User.find(item['created_by_id'])
        assets = user.assets(assets)
      end
      if item['updated_by_id']
        user = User.find(item['updated_by_id'])
        assets = user.assets(assets)
      end
    }
    assets
  end

  private

  def attachments_buffer
    @attachments_buffer_data
  end

  def attachments_buffer=(attachments)
    @attachments_buffer_data = attachments
  end

  def attachments_buffer_check

    # do nothing if no attachment exists
    return 1 if attachments_buffer.nil?

    # store attachments
    article_store = []
    attachments_buffer.each do |attachment|
      article_store.push Store.add(
        object: self.class.to_s,
        o_id: id,
        data: attachment.content,
        filename: attachment.filename,
        preferences: attachment.preferences,
        created_by_id: created_by_id,
      )
    end
    attachments_buffer = nil
  end

=begin

delete object recent viewed list, will be executed automatically

  model = Model.find(123)
  model.recent_view_destroy

=end

  def recent_view_destroy
    RecentView.log_destroy(self.class.to_s, id)
  end

=begin

check string/varchar size and cut them if needed

=end

  def check_limits
    attributes.each {|attribute|
      next if !self[ attribute[0] ]
      next if self[ attribute[0] ].class != String
      next if self[ attribute[0] ].empty?
      column = self.class.columns_hash[ attribute[0] ]
      next if !column
      limit = column.limit
      if column && limit
        current_length = attribute[1].to_s.length
        if limit < current_length
          logger.warn "WARNING: cut string because of database length #{self.class}.#{attribute[0]}(#{limit} but is #{current_length}:#{attribute[1]})"
          self[ attribute[0] ] = attribute[1][ 0, limit ]
        end
      end

      # strip 4 bytes utf8 chars if needed
      if column && self[ attribute[0] ]
        self[attribute[0]] = self[ attribute[0] ].utf8_to_3bytesutf8
      end
    }
  end

=begin

destory object dependencies, will be executed automatically

=end

  def destroy_dependencies
  end

end
