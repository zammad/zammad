class ObjectManager::Attribute < ApplicationModel
  include ChecksClientNotification
  include CanSeed

  self.table_name = 'object_manager_attributes'

  belongs_to :object_lookup

  validates :name, presence: true

  store :screens
  store :data_option
  store :data_option_new

  before_create :check_datatype
  before_update :check_datatype, :verify_possible_type_change

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
    references = ObjectManager::Attribute.attribute_to_references_hash
    attributes = []
    assets = {}
    result.each do |item|
      attribute = item.attributes
      attribute[:object] = ObjectLookup.by_id(item.object_lookup_id)
      attribute.delete('object_lookup_id')

      # an attribute is deletable if it is both editable and not referenced by other Objects (Triggers, Overviews, Schedulers)
      deletable = true
      not_deletable_reason = ''
      if ObjectManager::Attribute.attribute_used_by_references?(attribute[:object], attribute['name'], references)
        deletable = false
        not_deletable_reason = ObjectManager::Attribute.attribute_used_by_references_humaniced(attribute[:object], attribute['name'], references)
      end
      attribute[:deletable] = attribute['editable'] && deletable == true
      if not_deletable_reason.present?
        attribute[:not_deletable_reason] = "This attribute is referenced by #{not_deletable_reason} and thus cannot be deleted!"
      end
      attributes.push attribute
    end
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
        %i[name display data_type position active].each do |key|
          next if record[key] == data[key]
          record[:data_option_new] = data[:data_option] if data[:data_option] # bring the data options over as well, when there are changes to the fields above
          data[:to_config] = true
          break
        end

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
      data.each do |key, value|
        record[key.to_sym] = value
      end

      # check editable & name
      if !force
        record.check_editable
        record.check_name
      end
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
    elsif data[:object_lookup_id]
      data[:object] = ObjectLookup.by_id(data[:object_lookup_id])
    else
      raise 'ERROR: need object or object_lookup_id param!'
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

    # check to make sure that no triggers, overviews, or schedulers references this attribute
    if ObjectManager::Attribute.attribute_used_by_references?(data[:object], data[:name])
      text = ObjectManager::Attribute.attribute_used_by_references_humaniced(data[:object], data[:name])
      raise "ERROR: #{data[:object]}.#{data[:name]} is referenced by #{text} and thus cannot be deleted!"
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
    result.each do |item|
      data = {
        name: item.name,
        display: item.display,
        tag: item.data_type,
        #:null     => item.null,
      }
      if item.data_option[:permission]&.any?
        next if !user
        hint = false
        item.data_option[:permission].each do |permission|
          next if !user.permissions?(permission)
          hint = true
          break
        end
        next if !hint
      end

      if item.screens
        data[:screen] = {}
        item.screens.each do |screen, permission_options|
          data[:screen][screen] = {}
          permission_options.each do |permission, options|
            if permission == '-all-'
              data[:screen][screen] = options
            elsif user&.permissions?(permission)
              data[:screen][screen] = options
            end
          end
        end
      end
      if item.data_option
        data = data.merge(item.data_option.symbolize_keys)
      end
      attributes.push data
    end
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
    list.each do |item|
      hash[ item[:name] ] = item
    end
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
    ObjectManager::Attribute.where('to_delete = ? OR to_config = ?', true, true).each do |attribute|
      attribute.to_migrate = false
      attribute.to_delete = false
      attribute.to_config = false
      attribute.data_option_new = {}
      attribute.save
    end
    true
  end

=begin

check if we have pending migrations of attributes

  ObjectManager::Attribute.pending_migration?

returns

  true|false

=end

  def self.pending_migration?
    return false if migrations.blank?
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
    migrations.each do |attribute|
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
      if attribute.data_type.match?(/^input|select|tree_select|richtext|textarea|checkbox$/)
        data_type = :string
      elsif attribute.data_type.match?(/^integer|user_autocompletion$/)
        data_type = :integer
      elsif attribute.data_type.match?(/^boolean|active$/)
        data_type = :boolean
      elsif attribute.data_type.match?(/^datetime$/)
        data_type = :datetime
      elsif attribute.data_type.match?(/^date$/)
        data_type = :date
      end

      # change field
      if model.column_names.include?(attribute.name)
        if attribute.data_type.match?(/^input|select|tree_select|richtext|textarea|checkbox$/)
          ActiveRecord::Migration.change_column(
            model.table_name,
            attribute.name,
            data_type,
            limit: attribute.data_option[:maxlength],
            null: true
          )
        elsif attribute.data_type.match?(/^integer|user_autocompletion|datetime|date$/)
          ActiveRecord::Migration.change_column(
            model.table_name,
            attribute.name,
            data_type,
            default: attribute.data_option[:default],
            null: true
          )
        elsif attribute.data_type.match?(/^boolean|active$/)
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
      if attribute.data_type.match?(/^input|select|tree_select|richtext|textarea|checkbox$/)
        ActiveRecord::Migration.add_column(
          model.table_name,
          attribute.name,
          data_type,
          limit: attribute.data_option[:maxlength],
          null: true
        )
      elsif attribute.data_type.match?(/^integer|user_autocompletion$/)
        ActiveRecord::Migration.add_column(
          model.table_name,
          attribute.name,
          data_type,
          default: attribute.data_option[:default],
          null: true
        )
      elsif attribute.data_type.match?(/^boolean|active$/)
        ActiveRecord::Migration.add_column(
          model.table_name,
          attribute.name,
          data_type,
          default: attribute.data_option[:default],
          null: true
        )
      elsif attribute.data_type.match?(/^datetime|date$/)
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
    end

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

=begin

where attributes are used by triggers, overviews or schedulers

  result = ObjectManager::Attribute.attribute_to_references_hash

  result = {
    ticket.category: {
      Trigger: ['abc', 'xyz'],
      Overview: ['abc1', 'abc2'],
    },
    ticket.field_b: {
      Trigger: ['abc'],
      Overview: ['abc1', 'abc2'],
    },
  },

=end

  def self.attribute_to_references_hash
    objects = Trigger.select(:name, :condition) + Overview.select(:name, :condition) + Job.select(:name, :condition)
    attribute_list = {}
    objects.each do |item|
      item.condition.each do |condition_key, _condition_attributes|
        attribute_list[condition_key] ||= {}
        attribute_list[condition_key][item.class.name] ||= []
        next if attribute_list[condition_key][item.class.name].include?(item.name)
        attribute_list[condition_key][item.class.name].push item.name
      end
    end
    attribute_list
  end

=begin

is certain attribute used by triggers, overviews or schedulers

  ObjectManager::Attribute.attribute_used_by_references?('Ticket', 'attribute_name')

=end

  def self.attribute_used_by_references?(object_name, attribute_name, references = attribute_to_references_hash)
    references.each do |reference_key, _relations|
      local_object, local_attribute = reference_key.split('.')
      next if local_object != object_name.downcase
      next if local_attribute != attribute_name
      return true
    end
    false
  end

=begin

is certain attribute used by triggers, overviews or schedulers

  result = ObjectManager::Attribute.attribute_used_by_references('Ticket', 'attribute_name')

  result = {
    Trigger: ['abc', 'xyz'],
    Overview: ['abc1', 'abc2'],
  }

=end

  def self.attribute_used_by_references(object_name, attribute_name, references = attribute_to_references_hash)
    result = {}
    references.each do |reference_key, relations|
      local_object, local_attribute = reference_key.split('.')
      next if local_object != object_name.downcase
      next if local_attribute != attribute_name
      relations.each do |relation, relation_names|
        result[relation] ||= []
        result[relation].push relation_names.sort
      end
      break
    end
    result
  end

=begin

is certain attribute used by triggers, overviews or schedulers

  text = ObjectManager::Attribute.attribute_used_by_references_humaniced('Ticket', 'attribute_name', references)

=end

  def self.attribute_used_by_references_humaniced(object_name, attribute_name, references = nil)
    result = if references.present?
               ObjectManager::Attribute.attribute_used_by_references(object_name, attribute_name, references)
             else
               ObjectManager::Attribute.attribute_used_by_references(object_name, attribute_name)
             end
    not_deletable_reason = ''
    result.each do |relation, relation_names|
      if not_deletable_reason.present?
        not_deletable_reason += '; '
      end
      not_deletable_reason += "#{relation}: #{relation_names.sort.join(',')}"
    end
    not_deletable_reason
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

    raise 'Name can\'t get used, *_id and *_ids are not allowed' if name.match?(/_(id|ids)$/i) || name.match?(/^id$/i)
    raise 'Spaces in name are not allowed' if name.match?(/\s/)
    raise 'Only letters from a-z, numbers from 0-9, and _ are allowed' if !name.match?(/^[a-z0-9_]+$/)
    raise 'At least one letters is needed' if !name.match?(/[a-z]/)

    # do not allow model method names as attributes
    reserved_words = %w[destroy true false integer select drop create alter index table varchar blob date datetime timestamp]
    raise "#{name} is a reserved word, please choose a different one" if name.match?(/^(#{reserved_words.join('|')})$/)

    record = object_lookup.name.constantize.new
    return true if !record.respond_to?(name.to_sym)
    return true if record.attributes.key?(name)
    raise "#{name} is a reserved word, please choose a different one"
  end

  def check_editable
    return if editable
    raise 'Attribute not editable!'
  end

  private

  def check_datatype
    local_data_option = data_option
    if to_config == true
      local_data_option = data_option_new
    end
    if !data_type
      raise 'Need data_type param'
    end
    if !data_type.match?(/^(input|user_autocompletion|checkbox|select|tree_select|datetime|date|tag|richtext|textarea|integer|autocompletion_ajax|boolean|user_permission|active)$/)
      raise "Invalid data_type param '#{data_type}'"
    end

    if local_data_option.blank?
      raise 'Need data_option param'
    end
    if local_data_option[:null].nil?
      raise 'Need data_option[:null] param with true or false'
    end

    # validate data_option
    if data_type == 'input'
      raise 'Need data_option[:type] param e. g. (text|password|tel|fax|email|url)' if !local_data_option[:type]
      raise "Invalid data_option[:type] param '#{local_data_option[:type]}' (text|password|tel|fax|email|url)" if local_data_option[:type] !~ /^(text|password|tel|fax|email|url)$/
      raise 'Need data_option[:maxlength] param' if !local_data_option[:maxlength]
      raise "Invalid data_option[:maxlength] param #{local_data_option[:maxlength]}" if local_data_option[:maxlength].to_s !~ /^\d+?$/
    end

    if data_type == 'richtext'
      raise 'Need data_option[:maxlength] param' if !local_data_option[:maxlength]
      raise "Invalid data_option[:maxlength] param #{local_data_option[:maxlength]}" if local_data_option[:maxlength].to_s !~ /^\d+?$/
    end

    if data_type == 'integer'
      %i[min max].each do |item|
        raise "Need data_option[#{item.inspect}] param" if !local_data_option[item]
        raise "Invalid data_option[#{item.inspect}] param #{data_option[item]}" if local_data_option[item].to_s !~ /^\d+?$/
      end
    end

    if data_type == 'select' || data_type == 'tree_select' || data_type == 'checkbox'
      raise 'Need data_option[:default] param' if !local_data_option.key?(:default)
      raise 'Invalid data_option[:options] or data_option[:relation] param' if local_data_option[:options].nil? && local_data_option[:relation].nil?
      if !local_data_option.key?(:maxlength)
        local_data_option[:maxlength] = 255
      end
      if !local_data_option.key?(:nulloption)
        local_data_option[:nulloption] = true
      end
    end

    if data_type == 'boolean'
      raise 'Need data_option[:default] param true|false|undefined' if !local_data_option.key?(:default)
      raise 'Invalid data_option[:options] param' if local_data_option[:options].nil?
    end

    if data_type == 'datetime'
      raise 'Need data_option[:future] param true|false' if local_data_option[:future].nil?
      raise 'Need data_option[:past] param true|false' if local_data_option[:past].nil?
      raise 'Need data_option[:diff] param in hours' if local_data_option[:diff].nil?
    end

    if data_type == 'date'
      raise 'Need data_option[:future] param true|false' if local_data_option[:future].nil?
      raise 'Need data_option[:past] param true|false' if local_data_option[:past].nil?
      raise 'Need data_option[:diff] param in days' if local_data_option[:diff].nil?
    end

    true
  end

  def verify_possible_type_change
    return true if changes_to_save['data_type'].blank?

    possible = {
      'select' => %w[tree_select select input checkbox],
      'tree_select' => %w[tree_select select input checkbox],
      'checkbox' => %w[tree_select select input checkbox],
      'input' => %w[tree_select select input checkbox],
    }

    return true if possible[changes_to_save['data_type'][0]]&.include?(changes_to_save['data_type'][1])

    raise 'Can\'t be changed data_type of attribute. Drop the attribute and recreate it with new data_type.'
  end
end
