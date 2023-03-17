# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Condition
  include ::Mixin::HasBackends

  attr_accessor :user, :payload, :workflow, :attribute_object, :result_object, :check

  def initialize(result_object:, workflow:)
    @user             = result_object.user
    @payload          = result_object.payload
    @workflow         = workflow
    @attribute_object = result_object.attributes
    @result_object    = result_object
    @check            = nil
  end

  def attributes
    @attribute_object.send(@check)
  end

  def condition_key_value_object(key_split)
    case key_split[0]
    when 'session'
      key_split.shift
      obj = user
    when attributes.class.to_s.downcase
      key_split.shift
      obj = attributes
    else
      obj = attributes
    end
    obj
  end

  def condition_key_value(key)
    return Array(key) if key == 'custom.module'

    key_split = key.split('.')
    obj       = condition_key_value_object(key_split)
    key_split.each do |attribute|
      if obj.instance_of?(User) && attribute =~ %r{^group_ids_(full|create|change|read|overview)$}
        obj = obj.group_ids_access($1)
        break
      end

      obj = obj.try(attribute.to_sym)
      break if obj.blank?
    end

    condition_value_result(obj)
  end

  def condition_value_result(obj)
    Array(obj).map(&:to_s).map(&:html2text)
  end

  def condition_value_match?(key, condition, value)
    "CoreWorkflow::Condition::#{condition['operator'].tr(' ', '_').camelize}".constantize&.new(condition_object: self, key: key, condition: condition, value: value)&.match
  end

  def condition_match?(key, condition)
    value_key = condition_key_value(key)
    condition_value_match?(key, condition, value_key)
  end

  def condition_attributes_match?(check)
    @check = check

    condition = @workflow.send(:"condition_#{@check}")
    return true if condition.blank?

    result = true
    condition.each do |key, value|
      next if condition_match?(key, value)

      result = false

      break
    end

    result
  end

  def object_match?
    return true if @workflow.object.blank?

    @workflow.object.include?(@payload['class_name'])
  end

  def screen_match?
    return true if @workflow.preferences['screen'].blank?

    Array(@workflow.preferences['screen']).include?(@payload['screen'])
  end

  def match_all?
    return if !object_match?
    return if !screen_match?
    return if !condition_attributes_match?('saved')
    return if !condition_attributes_match?('selected')

    true
  end

end
