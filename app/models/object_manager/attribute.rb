# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ObjectManager::Attribute < ApplicationModel
  include ChecksClientNotification
  include CanSeed

  DATA_TYPES = %w[
    input
    user_autocompletion
    checkbox
    select
    tree_select
    datetime
    date
    tag
    richtext
    textarea
    integer
    autocompletion_ajax
    boolean
    user_permission
    active
  ].freeze

  self.table_name = 'object_manager_attributes'

  belongs_to :object_lookup, optional: true

  validates :name, presence: true
  validates :data_type, inclusion: { in: DATA_TYPES, msg: '%{value} is not a valid data type' } # rubocop:disable Style/FormatStringToken
  validate :inactive_must_be_unused_by_references, unless: :active?
  validate :data_option_must_have_appropriate_values
  validate :data_type_must_not_change, on: :update

  store :screens
  store :data_option
  store :data_option_new

  before_validation :set_base_options

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
    link_template: '',               # optional
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
    link_template: '',               # optional
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
      name:             data[:name],
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
      raise 'need object or object_lookup_id param!'
    end

    data[:name].downcase!

    # check newest entry - is needed
    record = ObjectManager::Attribute.find_by(
      object_lookup_id: data[:object_lookup_id],
      name:             data[:name],
    )
    if !record
      raise "No such field #{data[:object]}.#{data[:name]}"
    end

    if !data[:force] && !record.editable
      raise "#{data[:object]}.#{data[:name]} can't be removed!"
    end

    # check to make sure that no triggers, overviews, or schedulers references this attribute
    if ObjectManager::Attribute.attribute_used_by_references?(data[:object], data[:name])
      text = ObjectManager::Attribute.attribute_used_by_references_humaniced(data[:object], data[:name])
      raise "#{data[:object]}.#{data[:name]} is referenced by #{text} and thus cannot be deleted!"
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
      name:             data[:name],
    )
  end

=begin

discard migration changes

  ObjectManager::Attribute.discard_changes

returns

  true|false

=end

  def self.discard_changes
    ObjectManager::Attribute.where(to_create: true).each(&:destroy)
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
      model = attribute.object_lookup.name.constantize

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
        if attribute.data_type == 'select' && attribute.data_option[:options]
          historical_options = attribute.data_option[:historical_options] || {}
          historical_options.update(attribute.data_option[:options])
          historical_options.update(attribute.data_option_new[:options])
          attribute.data_option_new[:historical_options] = historical_options
        end
        attribute.data_option = attribute.data_option_new
        attribute.data_option_new = {}
        attribute.to_config = false
        attribute.save!
        next if !attribute.to_create && !attribute.to_migrate && !attribute.to_delete
      end

      if attribute.data_type == 'select' && attribute.data_option[:options]
        attribute.data_option[:historical_options] = attribute.data_option[:options]
      end

      data_type = nil
      case attribute.data_type
      when %r{^input|select|tree_select|richtext|textarea|checkbox$}
        data_type = :string
      when %r{^integer|user_autocompletion$}
        data_type = :integer
      when %r{^boolean|active$}
        data_type = :boolean
      when %r{^datetime$}
        data_type = :datetime
      when %r{^date$}
        data_type = :date
      end

      # change field
      if model.column_names.include?(attribute.name)
        case attribute.data_type
        when %r{^input|select|tree_select|richtext|textarea|checkbox$}
          ActiveRecord::Migration.change_column(
            model.table_name,
            attribute.name,
            data_type,
            limit: attribute.data_option[:maxlength],
            null:  true
          )
        when %r{^integer|user_autocompletion|datetime|date$}, %r{^boolean|active$}
          ActiveRecord::Migration.change_column(
            model.table_name,
            attribute.name,
            data_type,
            default: attribute.data_option[:default],
            null:    true
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
      case attribute.data_type
      when %r{^input|select|tree_select|richtext|textarea|checkbox$}
        ActiveRecord::Migration.add_column(
          model.table_name,
          attribute.name,
          data_type,
          limit: attribute.data_option[:maxlength],
          null:  true
        )
      when %r{^integer|user_autocompletion$}, %r{^boolean|active$}, %r{^datetime|date$}
        ActiveRecord::Migration.add_column(
          model.table_name,
          attribute.name,
          data_type,
          default: attribute.data_option[:default],
          null:    true
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
          AppVersionRestartJob.perform_later(ENV['APP_RESTART_CMD'])
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

    if name.match?(%r{.+?_(id|ids)$}i)
      errors.add(:name, "can't get used because *_id and *_ids are not allowed")
    end
    if name.match?(%r{\s})
      errors.add(:name, 'spaces are not allowed')
    end
    if !name.match?(%r{^[a-z0-9_]+$})
      errors.add(:name, 'Only letters from a-z because numbers from 0-9 and _ are allowed')
    end
    if !name.match?(%r{[a-z]})
      errors.add(:name, 'At least one letters is needed')
    end

    # do not allow model method names as attributes
    reserved_words = %w[destroy true false integer select drop create alter index table varchar blob date datetime timestamp url icon initials avatar permission validate subscribe unsubscribe translate search _type _doc _id id]
    if name.match?(%r{^(#{reserved_words.join('|')})$})
      errors.add(:name, "#{name} is a reserved word! (1)")
    end

    # fixes issue #2236 - Naming an attribute "attribute" causes ActiveRecord failure
    begin
      ObjectLookup.by_id(object_lookup_id).constantize.instance_method_already_implemented? name
    rescue ActiveRecord::DangerousAttributeError
      errors.add(:name, "#{name} is a reserved word! (2)")
    end

    record = object_lookup.name.constantize.new
    if record.respond_to?(name.to_sym) && record.attributes.key?(name) && new_record?
      errors.add(:name, "#{name} already exists!")
    end

    if errors.present?
      raise ActiveRecord::RecordInvalid, self
    end

    true
  end

  def check_editable
    return if editable

    errors.add(:name, 'Attribute not editable!')
    raise ActiveRecord::RecordInvalid, self
  end

  private

  # when setting default values for boolean fields,
  # favor #nil? tests over ||= (which will overwrite `false`)
  def set_base_options
    local_data_option[:null] = true if local_data_option[:null].nil?

    case data_type
    when %r{^((tree_)?select|checkbox)$}
      local_data_option[:nulloption] = true if local_data_option[:nulloption].nil?
      local_data_option[:maxlength] ||= 255
    end
  end

  def data_option_must_have_appropriate_values
    data_option_validations
      .select { |validation| validation[:failed] }
      .each { |validation| errors.add(local_data_attr, validation[:message]) }
  end

  def inactive_must_be_unused_by_references
    return if !ObjectManager::Attribute.attribute_used_by_references?(object_lookup.name, name)

    human_reference = ObjectManager::Attribute.attribute_used_by_references_humaniced(object_lookup.name, name)
    text            = "#{object_lookup.name}.#{name} is referenced by #{human_reference} and thus cannot be set to inactive!"

    # Adding as `base` to prevent `Active` prefix which does not look good on error message shown at the top of the form.
    errors.add(:base, text)
  end

  def data_type_must_not_change
    allowable_changes = %w[tree_select select input checkbox]

    return if !data_type_changed?
    return if (data_type_change - allowable_changes).empty?

    errors.add(:data_type, "can't be altered after creation " \
                           '(delete the attribute and create another with the desired value)')
  end

  def local_data_option
    @local_data_option ||= send(local_data_attr)
  end

  def local_data_attr
    @local_data_attr ||= to_config ? :data_option_new : :data_option
  end

  def local_data_option=(val)
    send("#{local_data_attr}=", val)
  end

  def data_option_validations
    case data_type
    when 'input'
      [{ failed:  %w[text password tel fax email url].exclude?(local_data_option[:type]),
         message: 'must have one of text/password/tel/fax/email/url for :type' },
       { failed:  !local_data_option[:maxlength].to_s.match?(%r{^\d+$}),
         message: 'must have integer for :maxlength' }]
    when 'richtext'
      [{ failed:  !local_data_option[:maxlength].to_s.match?(%r{^\d+$}),
         message: 'must have integer for :maxlength' }]
    when 'integer'
      [{ failed:  !local_data_option[:min].to_s.match?(%r{^\d+$}),
         message: 'must have integer for :min' },
       { failed:  !local_data_option[:max].to_s.match?(%r{^\d+$}),
         message: 'must have integer for :max' }]
    when %r{^((tree_)?select|checkbox)$}
      [{ failed:  !local_data_option.key?(:default),
         message: 'must have value for :default' },
       { failed:  local_data_option[:options].nil? && local_data_option[:relation].nil?,
         message: 'must have non-nil value for either :options or :relation' }]
    when 'boolean'
      [{ failed:  !local_data_option.key?(:default),
         message: 'must have boolean/undefined value for :default' },
       { failed:  local_data_option[:options].nil?,
         message: 'must have non-nil value for :options' }]
    when 'datetime'
      [{ failed:  local_data_option[:future].nil?,
         message: 'must have boolean value for :future' },
       { failed:  local_data_option[:past].nil?,
         message: 'must have boolean value for :past' },
       { failed:  local_data_option[:diff].nil?,
         message: 'must have integer value for :diff (in hours)' }]
    when 'date'
      [{ failed:  local_data_option[:diff].nil?,
         message: 'must have integer value for :diff (in days)' }]
    else
      []
    end
  end
end
