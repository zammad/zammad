# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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

  def condition_value
    Array(@condition['value']).map(&:to_s)
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
