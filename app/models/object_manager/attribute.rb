class ObjectManager::Attribute < ApplicationModel
  include ChecksClientNotification
  include CanSeed

  self.table_name = 'object_manager_attributes'

  belongs_to :object_lookup,   class_name: 'ObjectLookup'
  validates  :name, presence: true
  store      :screens
  store      :data_option
  store      :data_option_new

=begin

list of all attributes

  result = ObjectManager::Attribute.list_full

  result = [
    {
      name: 'some name',
      display: '...',
    }.
  ],

=end

  def self.list_full
    result = ObjectManager::Attribute.all.order('position ASC, name ASC')
    attributes = []
    assets = {}
    result.each { |item|
      attribute = item.attributes
      attribute[:object] = ObjectLookup.by_id(item.object_lookup_id)
      attribute.delete('object_lookup_id')
      attributes.push attribute
    }
    attributes
  end

=begin

add a new attribute entry for an object

  ObjectManager::Attribute.add(
    object: 'Ticket',
    name: 'group_id',
    display: 'Group',
    data_type: 'select',
    data_option: {
      relation: 'Group',
      relation_condition: { access: 'full' },
      multiple: false,
      null: true,
      translate: false,
    },
    active: true,
    screens: {
      create: {
        '-all-' => {
          required: true,
        },
      },
      edit: {
        'ticket.agent' => {
          required: true,
        },
      },
    },
    position: 20,
    created_by_id: 1,
    updated_by_id: 1,
    created_at: '2014-06-04 10:00:00',
    updated_at: '2014-06-04 10:00:00',

    force: true
    editable: false,
    to_migrate: false,
    to_create: false,
    to_delete: false,
    to_config: false,
  )

preserved name are

 /(_id|_ids)$/

possible types

# input

  data_type: 'input',
  data_option: {
    default: '',
    type: 'text', # text|email|url|tel
    maxlength: 200,
    null: true,
    note: 'some additional comment', # optional
  },

# select

  data_type: 'select',
  data_option: {
    default: 'aa',
    options: {
      'aa' => 'aa (comment)',
      'bb' => 'bb (comment)',
    },
    maxlength: 200,
    nulloption: true,
    null: false,
    multiple: false, # currently only "false" supported
    translate: true, # optional
    note: 'some additional comment', # optional
  },

# tree_select

  data_type: 'tree_select',
  data_option: {
    default: 'aa',
    options: [
      {
        'value'       => 'aa',
        'name'        => 'aa (comment)',
        'children'    => [
            {
              'value' => 'aaa',
              'name'  => 'aaa (comment)',
            },
            {
              'value' => 'aab',
              'name'  => 'aab (comment)',
            },
            {
              'value' => 'aac',
              'name'  => 'aac (comment)',
            },
        ]
      },
      {
        'value'       => 'bb',
        'name'        => 'bb (comment)',
        'children'    => [
            {
              'value' => 'bba',
              'name'  => 'aaa (comment)',
            },
            {
              'value' => 'bbb',
              'name'  => 'bbb (comment)',
            },
            {
              'value' => 'bbc',
              'name'  => 'bbc (comment)',
            },
        ]
      },
    ],
    maxlength: 200,
    nulloption: true,
    null: false,
    multiple: false, # currently only "false" supported
    translate: true, # optional
    note: 'some additional comment', # optional
  },

# checkbox

  data_type: 'checkbox',
  data_option: {
    default: 'aa',
    options: {
      'aa' => 'aa (comment)',
      'bb' => 'bb (comment)',
    },
    null: false,
    translate: true, # optional
    note: 'some additional comment', # optional
  },

# integer

  data_type: 'integer',
  data_option: {
    default: 5,
    min: 15,
    max: 999,
    null: false,
    note: 'some additional comment', # optional
  },

# boolean

  data_type: 'boolean',
  data_option: {
    default: true,
    options: {
      true => 'aa',
      false => 'bb',
    },
    null: false,
    translate: true, # optional
    note: 'some additional comment', # optional
  },

# datetime

  data_type: 'datetime',
  data_option: {
    future: true, # true|false
    past: true, # true|false
    diff: 12, # in hours
    null: false,
    note: 'some additional comment', # optional
  },

# date

  data_type: 'date',
  data_option: {
    future: true, # true|false
    past: true, # true|false
    diff: 15, # in days
    null: false,
    note: 'some additional comment', # optional
  },

# textarea

  data_type: 'textarea',
  data_option: {
    default: '',
    rows: 15,
    null: false,
    note: 'some additional comment', # optional
  },

# richtext

  data_type: 'richtext',
  data_option: {
    default: '',
    null: false,
    note: 'some additional comment', # optional
  },

=end

  def self.add(data)

    force = data[:force]
    data.delete(:force)

    # lookups
    if data[:object]
      data[:object_lookup_id] = ObjectLookup.by_name(data[:object])
    end
    data.delete(:object)

    data[:name].downcase!

    # check new entry - is needed
    record = ObjectManager::Attribute.find_by(
      object_lookup_id: data[:object_lookup_id],
      name: data[:name],
    )
    if record

      # do not allow to overwrite certain attributes
      if !force
        data.delete(:editable)
        data.delete(:to_create)
        data.delete(:to_migrate)
        data.delete(:to_delete)
        data.delete(:to_config)
      end

      # if data_option has changed, store it for next migration
      if !force
        [:name, :display, :data_type, :position, :active].each { |key|
          next if record[key] == data[key]
          data[:to_config] = true
          break
        }
        if record[:data_option] != data[:data_option]

          # do we need a database migration?
          if record[:data_option][:maxlength] && data[:data_option][:maxlength] && record[:data_option][:maxlength].to_s != data[:data_option][:maxlength].to_s
            data[:to_migrate] = true
          end

          record[:data_option_new] = data[:data_option]
          data.delete(:data_option)
          data[:to_config] = true
        end
      end

      # update attributes
      data.each { |key, value|
        record[key.to_sym] = value
      }

      # check editable & name
      if !force
        record.check_editable
        record.check_name
      end
      record.check_datatype
      record.save!
      return record
    end

    # do not allow to overwrite certain attributes
    if !force
      data[:editable] = true
      data[:to_create] = true
      data[:to_migrate] = true
      data[:to_delete] = false
    end

    record = ObjectManager::Attribute.new(data)

    # check editable & name
    if !force
      record.check_editable
      record.check_name
    end
    record.check_datatype
    record.save!
    record
  end

=begin

remove attribute entry for an object

  ObjectManager::Attribute.remove(
    object: 'Ticket',
    name: 'group_id',
  )

use "force: true" to delete also not editable fields

=end

  def self.remove(data)

    # lookups
    if data[:object]
      data[:object_lookup_id] = ObjectLookup.by_name(data[:object])
    end

    data[:name].downcase!

    # check newest entry - is needed
    record = ObjectManager::Attribute.find_by(
      object_lookup_id: data[:object_lookup_id],
      name: data[:name],
    )
    if !record
      raise "ERROR: No such field #{data[:object]}.#{data[:name]}"
    end

    if !data[:force] && !record.editable
      raise "ERROR: #{data[:object]}.#{data[:name]} can't be removed!"
    end

    # if record is to create, just destroy it
    if record.to_create
      record.destroy
      return true
    end

    record.to_delete = true
    record.save
  end

=begin

get the attribute model based on object and name

  attribute = ObjectManager::Attribute.get(
    object: 'Ticket',
    name: 'group_id',
  )

=end

  def self.get(data)

    # lookups
    if data[:object]
      data[:object_lookup_id] = ObjectLookup.by_name(data[:object])
    end

    data[:name].downcase!

    ObjectManager::Attribute.find_by(
      object_lookup_id: data[:object_lookup_id],
      name: data[:name],
    )
  end

=begin

get user based list of used object attributes

  attribute_list = ObjectManager::Attribute.by_object('Ticket', user)

returns:

  [
    { name: 'api_key', display: 'API KEY', tag: 'input', null: true, edit: true, maxlength: 32 },
    { name: 'api_ip_regexp', display: 'API IP RegExp', tag: 'input', null: true, edit: true },
    { name: 'api_ip_max', display: 'API IP Max', tag: 'input', null: true, edit: true },
  ]

=end

  def self.by_object(object, user)

    # lookups
    if object
      object_lookup_id = ObjectLookup.by_name(object)
    end

    # get attributes in right order
    result = ObjectManager::Attribute.where(
      object_lookup_id: object_lookup_id,
      active: true,
      to_create: false,
      to_delete: false,
    ).order('position ASC, name ASC')
    attributes = []
    result.each { |item|
      data = {
        name: item.name,
        display: item.display,
        tag: item.data_type,
        #:null     => item.null,
      }
      if item.data_option[:permission] && item.data_option[:permission].any?
        next if !user
        hint = false
        item.data_option[:permission].each { |permission|
          next if !user.permissions?(permission)
          hint = true
          break
        }
        next if !hint
      end

      if item.screens
        data[:screen] = {}
        item.screens.each { |screen, permission_options|
          data[:screen][screen] = {}
          permission_options.each { |permission, options|
            if permission == '-all-'
              data[:screen][screen] = options
            elsif user && user.permissions?(permission)
              data[:screen][screen] = options
            end
          }
        }
      end
      if item.data_option
        data = data.merge(item.data_option.symbolize_keys)
      end
      attributes.push data
    }
    attributes
  end

=begin

get user based list of object attributes as hash

  attribute_list = ObjectManager::Attribute.by_object_as_hash('Ticket', user)

returns:

  {
    'api_key'       => { name: 'api_key', display: 'API KEY', tag: 'input', null: true, edit: true, maxlength: 32 },
    'api_ip_regexp' => { name: 'api_ip_regexp', display: 'API IP RegExp', tag: 'input', null: true, edit: true },
    'api_ip_max'    => { name: 'api_ip_max', display: 'API IP Max', tag: 'input', null: true, edit: true },
  }

=end

  def self.by_object_as_hash(object, user)
    list = by_object(object, user)
    hash = {}
    list.each { |item|
      hash[ item[:name] ] = item
    }
    hash
  end

=begin

discard migration changes

  ObjectManager::Attribute.discard_changes

returns

  true|false

=end

  def self.discard_changes
    ObjectManager::Attribute.where('to_create = ?', true).each(&:destroy)
    ObjectManager::Attribute.where('to_delete = ? OR to_config = ?', true, true).each { |attribute|
      attribute.to_migrate = false
      attribute.to_delete = false
      attribute.to_config = false
      attribute.data_option_new = {}
      attribute.save
    }
    true
  end

=begin

check if we have pending migrations of attributes

  ObjectManager::Attribute.pending_migration?

returns

  true|false

=end

  def self.pending_migration?
    return false if migrations.empty?
    true
  end

=begin

get list of pending attributes migrations

  ObjectManager::Attribute.migrations

returns

  [record1, record2, ...]

=end

  def self.migrations
    ObjectManager::Attribute.where('to_create = ? OR to_migrate = ? OR to_delete = ? OR to_config = ?', true, true, true, true)
  end

=begin

start migration of pending attribute migrations

  ObjectManager::Attribute.migration_execute

returns

  [record1, record2, ...]

to send no browser reload event, pass false

  ObjectManager::Attribute.migration_execute(false)

=end

  def self.migration_execute(send_event = true)

    # check if field already exists
    execute_db_count = 0
    execute_config_count = 0
    migrations.each { |attribute|
      model = Kernel.const_get(attribute.object_lookup.name)

      # remove field
      if attribute.to_delete
        if model.column_names.include?(attribute.name)
          ActiveRecord::Migration.remove_column model.table_name, attribute.name
          reset_database_info(model)
        end
        execute_db_count += 1
        attribute.destroy
        next
      end

      # config changes
      if attribute.to_config
        execute_config_count += 1
        attribute.data_option = attribute.data_option_new
        attribute.data_option_new = {}
        attribute.to_config = false
        attribute.save!
        next if !attribute.to_create && !attribute.to_migrate && !attribute.to_delete
      end

      data_type = nil
      if attribute.data_type =~ /^input|select|tree_select|richtext|textarea|checkbox$/
        data_type = :string
      elsif attribute.data_type =~ /^integer|user_autocompletion$/
        data_type = :integer
      elsif attribute.data_type =~ /^boolean|active$/
        data_type = :boolean
      elsif attribute.data_type =~ /^datetime$/
        data_type = :datetime
      elsif attribute.data_type =~ /^date$/
        data_type = :date
      end

      # change field
      if model.column_names.include?(attribute.name)
        if attribute.data_type =~ /^input|select|tree_select|richtext|textarea|checkbox$/
          ActiveRecord::Migration.change_column(
            model.table_name,
            attribute.name,
            data_type,
            limit: attribute.data_option[:maxlength],
            null: true
          )
        elsif attribute.data_type =~ /^integer|user_autocompletion|datetime|date$/
          ActiveRecord::Migration.change_column(
            model.table_name,
            attribute.name,
            data_type,
            default: attribute.data_option[:default],
            null: true
          )
        elsif attribute.data_type =~ /^boolean|active$/
          ActiveRecord::Migration.change_column(
            model.table_name,
            attribute.name,
            data_type,
            default: attribute.data_option[:default],
            null: true
          )
        else
          raise "Unknown attribute.data_type '#{attribute.data_type}', can't update attribute"
        end

        # restart processes
        attribute.to_create = false
        attribute.to_migrate = false
        attribute.to_delete = false
        attribute.save!
        reset_database_info(model)
        execute_db_count += 1
        next
      end

      # create field
      if attribute.data_type =~ /^input|select|tree_select|richtext|textarea|checkbox$/
        ActiveRecord::Migration.add_column(
          model.table_name,
          attribute.name,
          data_type,
          limit: attribute.data_option[:maxlength],
          null: true
        )
      elsif attribute.data_type =~ /^integer|user_autocompletion$/
        ActiveRecord::Migration.add_column(
          model.table_name,
          attribute.name,
          data_type,
          default: attribute.data_option[:default],
          null: true
        )
      elsif attribute.data_type =~ /^boolean|active$/
        ActiveRecord::Migration.add_column(
          model.table_name,
          attribute.name,
          data_type,
          default: attribute.data_option[:default],
          null: true
        )
      elsif attribute.data_type =~ /^datetime|date$/
        ActiveRecord::Migration.add_column(
          model.table_name,
          attribute.name,
          data_type,
          default: attribute.data_option[:default],
          null: true
        )
      else
        raise "Unknown attribute.data_type '#{attribute.data_type}', can't create attribute"
      end

      # restart processes
      attribute.to_create = false
      attribute.to_migrate = false
      attribute.to_delete = false
      attribute.save!

      reset_database_info(model)
      execute_db_count += 1
    }

    # sent maintenance message to clients
    if send_event
      if execute_db_count.nonzero?
        if ENV['APP_RESTART_CMD']
          AppVersion.set(true, 'restart_auto')
          sleep 4
          Delayed::Job.enqueue(Observer::AppVersionRestartJob.new(ENV['APP_RESTART_CMD']))
        else
          AppVersion.set(true, 'restart_manual')
        end
      elsif execute_config_count.nonzero?
        AppVersion.set(true, 'config_changed')
      end
    end
    true
  end

  def self.reset_database_info(model)
    model.connection.schema_cache.clear!
    model.reset_column_information
    # rebuild columns cache to reduce the risk of
    # race conditions in re-setting it with outdated data
    model.columns
  end

  def check_name
    return if !name
    if name =~ /_(id|ids)$/i || name =~ /^id$/i
      raise 'Name can\'t get used, *_id and *_ids are not allowed'
    elsif name =~ /\s/
      raise 'Spaces in name are not allowed'
    elsif name !~ /^[a-z0-9_]+$/
      raise 'Only letters from a-z, numbers from 0-9, and _ are allowed'
    elsif name !~ /[a-z]/
      raise 'At least one letters is needed'
    elsif name =~ /^(destroy|true|false|integer|select|drop|create|alter|index|table|varchar|blob|date|datetime|timestamp)$/
      raise "#{name} is a reserved word, please choose a different one"

    # do not allow model method names as attributes
    else
      model = Kernel.const_get(object_lookup.name)
      record = model.new
      if record.respond_to?(name.to_sym) && !record.attributes.key?(name)
        raise "#{name} is a reserved word, please choose a different one"
      end
    end
    true
  end

  def check_editable
    return if editable
    raise 'Attribute not editable!'
  end

  def check_datatype
    if !data_type
      raise 'Need data_type param'
    end
    if data_type !~ /^(input|user_autocompletion|checkbox|select|tree_select|datetime|date|tag|richtext|textarea|integer|autocompletion_ajax|boolean|user_permission|active)$/
      raise "Invalid data_type param '#{data_type}'"
    end

    if !data_option
      raise 'Need data_type param'
    end
    if data_option[:null].nil?
      raise 'Need data_option[:null] param with true or false'
    end

    # validate data_option
    if data_type == 'input'
      raise 'Need data_option[:type] param' if !data_option[:type]
      raise "Invalid data_option[:type] param '#{data_option[:type]}'" if data_option[:type] !~ /^(text|password|tel|fax|email|url)$/
      raise 'Need data_option[:maxlength] param' if !data_option[:maxlength]
      raise "Invalid data_option[:maxlength] param #{data_option[:maxlength]}" if data_option[:maxlength].to_s !~ /^\d+?$/
    end

    if data_type == 'richtext'
      raise 'Need data_option[:maxlength] param' if !data_option[:maxlength]
      raise "Invalid data_option[:maxlength] param #{data_option[:maxlength]}" if data_option[:maxlength].to_s !~ /^\d+?$/
    end

    if data_type == 'integer'
      [:min, :max].each { |item|
        raise "Need data_option[#{item.inspect}] param" if !data_option[item]
        raise "Invalid data_option[#{item.inspect}] param #{data_option[item]}" if data_option[item].to_s !~ /^\d+?$/
      }
    end

    if data_type == 'select' || data_type == 'tree_select' || data_type == 'checkbox'
      raise 'Need data_option[:default] param' if !data_option.key?(:default)
      raise 'Invalid data_option[:options] or data_option[:relation] param' if data_option[:options].nil? && data_option[:relation].nil?
      if !data_option.key?(:maxlength)
        data_option[:maxlength] = 255
      end
      if !data_option.key?(:nulloption)
        data_option[:nulloption] = true
      end
    end

    if data_type == 'boolean'
      raise 'Need data_option[:default] param true|false|undefined' if !data_option.key?(:default)
      raise 'Invalid data_option[:options] param' if data_option[:options].nil?
    end

    if data_type == 'datetime'
      raise 'Need data_option[:future] param true|false' if data_option[:future].nil?
      raise 'Need data_option[:past] param true|false' if data_option[:past].nil?
      raise 'Need data_option[:diff] param in hours' if data_option[:diff].nil?
    end

    if data_type == 'date'
      raise 'Need data_option[:future] param true|false' if data_option[:future].nil?
      raise 'Need data_option[:past] param true|false' if data_option[:past].nil?
      raise 'Need data_option[:diff] param in days' if data_option[:diff].nil?
    end

  end

end
