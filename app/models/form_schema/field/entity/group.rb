# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class FormSchema::Field::Entity::Group < FormSchema::Field
  attribute :placeholder

  def self.type
    'select'
  end

  def schema
    options = []
    ::Group.where(active: true).each do |group|
      options.push({ value: id_from_object(group), label: group.name })
    end
    super.tap { |schema| schema[:props][:options] = options }
  end
end
