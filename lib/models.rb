# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
    @all ||= begin
      all    = {}
      dir    = Rails.root.join('app/models').to_s
      tables = ActiveRecord::Base.connection.tables
      Dir.glob("#{dir}/**/*.rb") do |entry|
        next if entry.match?(%r{application_model}i)
        next if entry.match?(%r{channel/}i)
        next if entry.match?(%r{observer/}i)
        next if entry.match?(%r{store/provider/}i)
        next if entry.match?(%r{models/concerns/}i)
        next if entry.match?(%r{models/object_manager/attribute/validation/}i)

        entry.gsub!(dir, '')
        entry = entry.to_classname
        model_class = entry.constantize
        next if !model_class.respond_to? :new
        next if !model_class.respond_to? :table_name

        table_name = model_class.table_name # handle models where not table exists, pending migrations
        next if tables.exclude?(table_name)

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
  end

=begin

get list of searchable models for UI

  result = Models.searchable

returns

  [Model1, Model2, Model3]

=end

  def self.searchable
    @searchable ||= Models.all.keys.select { |model| model.respond_to?(:search_preferences) }
  end

=begin

get list of indexable models

  result = Models.indexable

returns

  [Model1, Model2, Model3]

=end

  def self.indexable
    @indexable ||= Models.all.keys.select { |model| model.method_defined?(:search_index_update_backend) }
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

  def self.references(object_name, object_id, include_zero = false)
    object_name = object_name.to_s

    # check if model exists
    object_name.constantize.find(object_id)

    list       = all
    references = {}

    # find relations via attributes
    ref_attributes = ["#{object_name.downcase}_id"]

    # for users we do not define relations for created_by_id &
    # updated_by_id - add it here directly
    if object_name == 'User'
      ref_attributes.push 'created_by_id'
      ref_attributes.push 'updated_by_id'
      ref_attributes.push 'out_of_office_replacement_id'
    end
    list.each do |model_class, model_attributes|
      if !references[model_class.to_s]
        references[model_class.to_s] = {}
      end

      next if !model_attributes[:attributes]

      ref_attributes.each do |item|
        next if model_attributes[:attributes].exclude?(item)

        count = model_class.where("#{item} = ?", object_id).count
        next if count.zero? && !include_zero

        if !references[model_class.to_s][item]
          references[model_class.to_s][item] = 0
        end
        Rails.logger.debug { "FOUND (by id) #{model_class}->#{item} #{count}!" }
        references[model_class.to_s][item] += count
      end
    end

    # find relations via reflections
    list.each do |model_class, model_attributes| # rubocop:disable Style/CombinableLoops
      next if !model_attributes[:reflections]

      model_attributes[:reflections].each_value do |reflection_value|

        next if reflection_value.macro != :belongs_to

        col_name = "#{reflection_value.name}_id"
        next if ref_attributes.include?(col_name)

        if reflection_value.options[:class_name] == object_name
          count = model_class.where("#{col_name} = ?", object_id).count
          next if count.zero? && !include_zero

          if !references[model_class.to_s][col_name]
            references[model_class.to_s][col_name] = 0
          end
          Rails.logger.debug { "FOUND (by ref without class) #{model_class}->#{col_name} #{count}!" }
          references[model_class.to_s][col_name] += count
        end

        next if reflection_value.options[:class_name]
        next if reflection_value.name != object_name.downcase.to_sym

        count = model_class.where("#{col_name} = ?", object_id).count
        next if count.zero? && !include_zero

        if !references[model_class.to_s][col_name]
          references[model_class.to_s][col_name] = 0
        end
        Rails.logger.debug { "FOUND (by ref with class) #{model_class}->#{col_name} #{count}!" }
        references[model_class.to_s][col_name] += count
      end
    end

    # cleanup, remove models with empty references
    references.each do |k, v|
      next if v.present?

      references.delete(k)
    end

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
    references.each_value do |model_references|
      model_references.each_value do |count|
        total += count
      end
    end
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
    references.each do |model, attributes|
      model_object = model.constantize

      # collect items and attributes to update
      items_to_update = {}
      attributes.each_key do |attribute|
        Rails.logger.debug { "#{object_name}: #{model}.#{attribute}->#{object_id_to_merge}->#{object_id_primary}" }
        model_object.where("#{attribute} = ?", object_id_to_merge).each do |item|
          if !items_to_update[item.id]
            items_to_update[item.id] = item
          end
          items_to_update[item.id][attribute.to_sym] = object_id_primary
        end
      end

      # update items
      ActiveRecord::Base.transaction do
        items_to_update.each_value(&:save!)
      end
    end

    ExternalSync.migrate(object_name, object_id_primary, object_id_to_merge)

    true
  end
end
