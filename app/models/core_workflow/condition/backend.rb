# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Condition::Backend
  def initialize(condition_object:, result_object:, key:, condition:, value:)
    @key              = key
    @condition_object = condition_object
    @result_object    = result_object
    @condition        = condition
    @value            = value
  end

  attr_reader :value

  def field
    @key.sub(%r{.*\.}, '')
  end

  def object?(object)
    @condition_object.attributes.instance_of?(object)
  end

  def selected
    @condition_object.attribute_object.selected
  end

  def condition_value
    Array.wrap(@condition['value']).map do |v|
      if v.is_a?(Hash)
        v[:value].to_s
      else
        v.to_s
      end
    end
  end

  def time_modifier
    if ['before (relative)', 'within last (relative)', 'from (relative)'].include?(@condition['operator'])
      -1
    else
      1
    end
  end

  def condition_times
    return condition_value.map { |v| TimeRangeHelper.relative(range: @condition['range'], value: time_modifier * v.to_i) } if @condition['range']

    condition_value.map { |v| Time.zone.parse(v) }
  end

  def value_times
    value.map { |v| Time.zone.parse(v) }
  end

  def match
    false
  end
end
