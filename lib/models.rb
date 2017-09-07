class Models
  include ApplicationLib

=begin

get list of models

  result = Models.all

returns

  {
    Some::Classname1 => {
      attributes: ['id', 'name', '...'],
      reflections: ...model.reflections...,
      table: 'some_classname1s',
    },
    Some::Classname2 => {
      attributes: ['id', 'name', '...']
      reflections: ...model.reflections...
      table: 'some_classname2s',
    },
  }

=end

  def self.all
    all = {}
    dir = "#{Rails.root}/app/models/"
    Dir.glob( "#{dir}**/*.rb" ) do |entry|
      next if entry =~ /application_model/i
      next if entry =~ %r{channel/}i
      next if entry =~ %r{observer/}i
      next if entry =~ %r{store/provider/}i
      next if entry =~ %r{models/concerns/}i

      entry.gsub!(dir, '')
      entry = entry.to_classname
      model_class = load_adapter(entry)
      next if !model_class
      next if !model_class.respond_to? :new
      next if !model_class.respond_to? :table_name
      table_name = model_class.table_name # handle models where not table exists, pending migrations
      next if !ActiveRecord::Base.connection.tables.include?(table_name)
      model_object = model_class.new
      next if !model_object.respond_to? :attributes
      all[model_class] = {}
      all[model_class][:attributes] = model_class.attribute_names
      all[model_class][:reflections] = model_class.reflections
      all[model_class][:table] = model_class.table_name
      #puts model_class
      #puts "rrrr #{all[model_class][:attributes]}"
      #puts " #{model_class.attribute_names.inspect}"
    end
    all
  end

=begin

get list of searchable models

  result = Models.searchable

returns

  [Model1, Model2, Model3]

=end

  def self.searchable
    models = []
    all.each { |model_class, _options|
      next if !model_class
      next if !model_class.respond_to? :search_preferences
      models.push model_class
    }
    models
  end

=begin

get reference list of a models

  result = Models.references('User', 2)

returns

  {
    'Some::Classname1' => {
      attribute1: 12,
      attribute2: 6,
    },
    'Some::Classname2' => {
      updated_by_id: 12,
      created_by_id: 6,
    },
  }

=end

  def self.references(object_name, object_id)
    object_name = object_name.to_s

    # check if model exists
    object_model = load_adapter(object_name)
    object_model.find(object_id)

    list       = all
    references = {}

    # find relations via attributes
    ref_attributes = ["#{object_name.downcase}_id"]

    # for users we do not define relations for created_by_id &
    # updated_by_id - add it here directly
    if object_name == 'User'
      ref_attributes.push 'created_by_id'
      ref_attributes.push 'updated_by_id'
    end
    list.each { |model_class, model_attributes|
      if !references[model_class.to_s]
        references[model_class.to_s] = {}
      end

      next if !model_attributes[:attributes]
      ref_attributes.each { |item|
        next if !model_attributes[:attributes].include?(item)

        count = model_class.where("#{item} = ?", object_id).count
        next if count.zero?
        if !references[model_class.to_s][item]
          references[model_class.to_s][item] = 0
        end
        Rails.logger.debug "FOUND (by id) #{model_class}->#{item} #{count}!"
        references[model_class.to_s][item] += count
      }
    }

    # find relations via reflections
    list.each { |model_class, model_attributes|
      next if !model_attributes[:reflections]
      model_attributes[:reflections].each { |_reflection_key, reflection_value|

        next if reflection_value.macro != :belongs_to
        col_name = "#{reflection_value.name}_id"
        next if ref_attributes.include?(col_name)

        if reflection_value.options[:class_name] == object_name
          count = model_class.where("#{col_name} = ?", object_id).count
          next if count.zero?
          if !references[model_class.to_s][col_name]
            references[model_class.to_s][col_name] = 0
          end
          Rails.logger.debug "FOUND (by ref without class) #{model_class}->#{col_name} #{count}!"
          references[model_class.to_s][col_name] += count
        end

        next if reflection_value.options[:class_name]
        next if reflection_value.name != object_name.downcase.to_sym

        count = model_class.where("#{col_name} = ?", object_id).count
        next if count.zero?
        if !references[model_class.to_s][col_name]
          references[model_class.to_s][col_name] = 0
        end
        Rails.logger.debug "FOUND (by ref with class) #{model_class}->#{col_name} #{count}!"
        references[model_class.to_s][col_name] += count
      }
    }

    # cleanup, remove models with empty references
    references.each { |k, v|
      next if !v.empty?
      references.delete(k)
    }

    references
  end

=begin

get reference total of a models

  count = Models.references_total('User', 2)

returns

  count # 1234

=end

  def self.references_total(object_name, object_id)
    references = references(object_name, object_id)
    total = 0
    references.each { |_model, model_references|
      model_references.each { |_col, count|
        total += count
      }
    }
    total
  end

=begin

merge model references to other model

  result = Models.merge('User', 2, 4711) # Object, object_id_of_primary, object_id_which_should_be_merged

returns

  true # false

=end

  def self.merge(object_name, object_id_primary, object_id_to_merge, force = false)

    # if lower x references to update, do it right now
    if force
      total = references_total(object_name, object_id_to_merge)
      if total > 1000
        raise "Can't merge object because object has more then 1000 (#{total}) references, please contact your system administrator."
      end
    end

    # update references
    references = references(object_name, object_id_to_merge)
    references.each { |model, attributes|
      model_object = Object.const_get(model)

      # collect items and attributes to update
      items_to_update = {}
      attributes.each { |attribute, _count|
        Rails.logger.debug "#{object_name}: #{model}.#{attribute}->#{object_id_to_merge}->#{object_id_primary}"
        model_object.where("#{attribute} = ?", object_id_to_merge).each { |item|
          if !items_to_update[item.id]
            items_to_update[item.id] = item
          end
          items_to_update[item.id][attribute.to_sym] = object_id_primary
        }
      }

      # update items
      ActiveRecord::Base.transaction do
        items_to_update.each { |_id, item|
          item.save!
        }
      end
    }
    true
  end
end
