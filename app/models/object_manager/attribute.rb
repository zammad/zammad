class ObjectManager::Attribute < ApplicationModel
  self.table_name = 'object_manager_attributes'
  belongs_to :object_lookup,   class_name: 'ObjectLookup'
  validates  :name, presence: true
  store      :screens
  store      :data_option

  notify_clients_support

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
    result = ObjectManager::Attribute.all
    attributes = []
    assets = {}
    result.each {|item|
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
      relation_condition: { access: 'rw' },
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
        Agent : {
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
  )

preserved name are

 /(_id|_ids)$/

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
      end
      # update attributes
      data.each {|key, value|
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
    ).order('position ASC')
    attributes = []
    result.each {|item|
      data = {
        name: item.name,
        display: item.display,
        tag: item.data_type,
        #:null     => item.null,
      }
      if item.screens
        data[:screen] = {}
        item.screens.each {|screen, roles_options|
          data[:screen][screen] = {}
          roles_options.each {|role, options|
            if role == '-all-'
              data[:screen][screen] = options
            elsif user && user.role?(role)
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
    list.each {|item|
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
    ObjectManager::Attribute.where('to_delete = ?', true).each {|attribute|
      attribute.to_delete = false
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
    ObjectManager::Attribute.where('to_create = ? OR to_migrate = ? OR to_delete = ?', true, true, true)
  end

=begin

start migration of pending attribute migrations

  ObjectManager::Attribute.migration_execute

returns

  [record1, record2, ...]

=end

  def self.migration_execute

    # check if field already exists
    execute_count = 0
    migrations.each {|attribute|
      model = Kernel.const_get(attribute.object_lookup.name)

      # remove field
      if attribute.to_delete
        if model.column_names.include?(attribute.name)
          ActiveRecord::Migration.remove_column model.table_name, attribute.name
          model.reset_column_information
          execute_count += 1
        end
        attribute.destroy
        next
      end

      data_type = nil
      if attribute.data_type =~ /^input|select|richtext|textarea|checkbox$/
        data_type = :string
      elsif attribute.data_type =~ /^integer$/
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
        if attribute.data_type =~ /^input|select|richtext|textarea|checkbox$/
          ActiveRecord::Migration.change_column(
            model.table_name,
            attribute.name,
            data_type,
            limit: attribute.data_option[:maxlength],
            null: true
          )
        elsif attribute.data_type =~ /^integer|datetime|date$/
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
            null: false
          )
        else
          raise "Unknown attribute.data_type '#{attribute.data_type}', can't update attribute"
        end

        # restart processes
        attribute.to_migrate = false
        attribute.save!
        model.reset_column_information
        execute_count += 1
        next
      end

      # create field
      if attribute.data_type =~ /^input|select|richtext|textarea|checkbox$/
        ActiveRecord::Migration.add_column(
          model.table_name,
          attribute.name,
          data_type,
          limit: attribute.data_option[:maxlength],
          null: true
        )
      elsif attribute.data_type =~ /^integer$/
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
          null: false
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

      model.reset_column_information
      execute_count += 1
    }

    # sent reload to clients
    if execute_count != 0
      AppVersion.set(true)
    end
    true
  end

  def check_name
    return if !name
    if name =~ /_(id|ids)$/i || name =~ /^id$/i
      raise 'Name can\'t get used, *_id and *_ids are not allowed'
    elsif name =~ /\s/
      raise 'Spaces in name are not allowed'
    elsif name !~ /^[a-z0-9_]+$/
      raise 'Only letters from a-z, numbers from 0-9, and _ are allowed'
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
    if data_type !~ /^(input|user_autocompletion|checkbox|select|datetime|date|tag|richtext|textarea|integer|autocompletion_ajax|boolean|user_permission|active)$/
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
      raise "Invalid data_option[:type] param '#{data_option[:type]}'" if data_option[:type] !~ /^(text|password|phone|fax|email|url)$/
      raise 'Need data_option[:maxlength] param' if !data_option[:maxlength]
      raise "Invalid data_option[:maxlength] param #{data_option[:maxlength]}" if data_option[:maxlength].to_s !~ /^\d+?$/
    end

    if data_type == 'integer'
      [:min, :max].each {|item|
        raise "Need data_option[#{item.inspect}] param" if !data_option[item]
        raise "Invalid data_option[#{item.inspect}] param #{data_option[item]}" if data_option[item].to_s !~ /^\d+?$/
      }
    end

    if data_type == 'select' || data_type == 'checkbox'
      raise 'Need data_option[:default] param' if data_option[:default].nil?
      raise 'Invalid data_option[:options] or data_option[:relation] param' if data_option[:options].nil? && data_option[:relation].nil?
    end

    if data_type == 'boolean'
      raise 'Need data_option[:default] param true|false' if data_option[:default].nil?
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
