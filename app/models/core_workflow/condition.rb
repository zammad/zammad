# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Condition
  include ::Mixin::HasBackends

  attr_accessor :user, :payload, :workflow, :attribute_object, :result_object, :check

  def initialize(result_object:, workflow: nil)
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
    when 'article'
      key_split.shift
      obj = @attribute_object.article
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

  def condition_key_value_tags(attribute, obj)
    return if !obj.instance_of?(Ticket)
    return if attribute != 'tags'

    params_tags = payload.dig('params', 'tags')
    tags        = obj.try(:tag_list)

    if @check == 'selected'
      tags += if params_tags.is_a?(Array)
                params_tags
              else
                params_tags.to_s.split(', ')
              end
    end
    tags
  end

  def condition_key_value_group_permissions(attribute, obj)
    return if !obj.instance_of?(User)
    return if attribute !~ %r{^group_ids_(full|create|change|read|overview)$}

    obj.group_ids_access($1)
  end

  def condition_key_value_obj(attribute, obj)
    obj.try(attribute.to_sym)
  end

  def condition_key_value(key)
    return Array(key) if key == 'custom.module'

    key_split = key.split('.')
    obj       = condition_key_value_object(key_split)
    key_split.each do |attribute|
      obj = condition_key_value_tags(attribute, obj) || condition_key_value_group_permissions(attribute, obj) || condition_key_value_obj(attribute, obj)
    end

    condition_value_result(obj)
  end

  def condition_value_result(obj)
    Array.wrap(obj).map do |v|
      if v.is_a?(Hash)
        v['value'].to_s.html2text
      else
        v.to_s.html2text
      end
    end
  end

  def condition_value_match?(key, condition, value)
    "CoreWorkflow::Condition::#{condition['operator'].tr(' ()', '_').camelize}".constantize&.new(condition_object: self, result_object: result_object, key: key, condition: condition, value: value)&.match
  end

  def pre_condition(condition)
    pre_condition_current_user(condition)
    pre_condition_not_set(condition)
  end

  def pre_condition_current_user(condition)
    return if condition['pre_condition'] != 'current_user.id'

    condition['value'] = [user.id.to_s]
  end

  def pre_condition_not_set(condition)
    return if condition['pre_condition'] != 'not_set'

    condition['operator'] = 'not_set'
  end

  def condition_match?(key, condition)
    pre_condition(condition)
    value_key = condition_key_value(key)
    condition_value_match?(key, condition, value_key)
  end

  def condition_selector_match?(selector)
    result = true
    selector.each do |key, value|
      next if condition_match?(key, value)

      result = false

      break
    end
    result
  end

  def condition_attributes_match?(check)
    @check = check

    condition = @workflow.send(:"condition_#{@check}")
    return true if condition.blank?

    condition_selector_match?(condition)
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
