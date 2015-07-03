class Models
  include ApplicationLib

=begin

get list of models

  result = Models.all

returns

  {
    'Some::Classname1' => {
      attributes: ['id', 'name', '...']
      reflections: ...model.reflections...
    },
    'Some::Classname2' => {
      attributes: ['id', 'name', '...']
      reflections: ...model.reflections...
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
      entry.gsub!(dir, '')
      entry = entry.to_classname
      model_class = load_adapter(entry)
      next if !model_class
      next if !model_class.respond_to? :new
      model_object = model_class.new
      next if !model_object.respond_to? :attributes
      all[model_class] = {}
      all[model_class][:attributes] = model_class.attribute_names
      all[model_class][:reflections] = model_class.reflections
      #puts "rrrr #{all[model_class][:attributes]}"
      #puts model.class
      #puts " #{model.attribute_names.inspect}"
    end
    all
  end

=begin

get reference list of a models

  result = Models.references('User', 2)

returns

  {
    'Some::Classname1' => {
      attributes: ['id', 'name', '...']
      reflections: ...model.reflections...
    },
    'Some::Classname2' => {
      attributes: ['id', 'name', '...']
      reflections: ...model.reflections...
    },
  }

=end

  def self.references(object_name, object_id)
    object_model = load_adapter(object_name)
    object_model.find(object_id)
    list       = all
    references = {
      model: {},
      total: 0,
    }

    # find relations via attributes
    list.each {|model_class, model_attributes|
      references[:model][model_class.to_s] = 0
      next if !model_attributes[:attributes]
      %w(created_by_id updated_by_id).each {|item|

        next if !model_attributes[:attributes].include?(item)

        count = model_class.where("#{item} = ?", object_id).count
        next if count == 0
        Rails.logger.debug "FOUND (by id) #{model_class}->#{item} #{count}!"
        references[:model][model_class.to_s] += count
      }
    }

    # find relations via reflections
    list.each {|model_class, model_attributes|
      next if !model_attributes[:reflections]
      model_attributes[:reflections].each {|reflection_key, reflection_value|

        next if reflection_value.macro != :belongs_to

        if reflection_value.options[:class_name] == object_name
          count = model_class.where("#{reflection_value.name}_id = ?", object_id).count
          next if count == 0
          Rails.logger.debug "FOUND (by ref without class) #{model_class}->#{reflection_value.name} #{count}!"
          references[:model][model_class.to_s] += count
        end

        next if reflection_value.options[:class_name]
        next if reflection_value.name != object_name.downcase.to_sym

        count = model_class.where("#{reflection_value.name}_id = ?", object_id).count
        next if count == 0

        Rails.logger.debug "FOUND (by ref with class) #{model_class}->#{reflection_value.name} #{count}!"
        references[:model][model_class.to_s] += count
      }
    }

    references[:model].each {|k, v|
      next if v == 0
      references[:total] += v
    }
    references
  end

end
