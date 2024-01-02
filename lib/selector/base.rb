# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Selector::Base
  attr_accessor :selector, :options, :changed_attributes, :target_class, :target_table, :target_name

  def initialize(selector:, options:, target_class: Ticket)
    if selector.respond_to?(:permit!)
      selector = selector.permit!.to_h
    end

    @selector                   = Marshal.load(Marshal.dump(selector)).deep_symbolize_keys
    @options                    = options
    @target_class               = target_class
    @target_table               = target_class.table_name
    @target_name                = target_table.delete_suffix('s')
    @changed_attributes         = {}
    @options[:changes]        ||= {}

    migrate
    set_static_conditions
    check_changes
  end

  def migrate
    return if !selector[:conditions].nil?

    result = {
      operator:   'AND',
      conditions: [],
    }

    selector.each_key do |key|
      result[:conditions] << {
        name: key.to_s,
      }.merge(selector[key])
    end

    @selector = result
  end

  def set_static_conditions
    conditions = static_conditions_ticket + static_conditions_article + static_conditions_merged + static_conditions_ticket_update + static_conditions_user_one
    return if conditions.blank?

    @selector = {
      operator:   'AND',
      conditions: conditions + [@selector]
    }
  end

  def static_conditions_ticket
    return [] if options[:ticket_id].blank?

    [
      {
        name:     'ticket.id',
        operator: 'is',
        value:    options[:ticket_id]
      }
    ]
  end

  def static_conditions_article
    return [] if options[:article_id].blank?

    [
      {
        name:     'article.id',
        operator: 'is',
        value:    options[:article_id]
      }
    ]
  end

  def static_conditions_merged
    return [] if options[:exclude_merged].blank?

    [
      {
        name:     'ticket_state.name',
        operator: 'is not',
        value:    Ticket::StateType.find_by(name: 'merged').states.pluck(:name),
      }
    ]
  end

  # https://github.com/zammad/zammad/issues/4550
  def static_conditions_ticket_update
    return [] if options[:ticket_action] != 'update' || options[:changes_required].blank?

    [
      {
        name:     'ticket.action',
        operator: 'is',
        value:    'update'
      }
    ]
  end

  def static_conditions_user_one
    return [] if target_class != User

    [
      {
        name:     'user.id',
        operator: 'is not',
        value:    '1'
      }
    ]
  end

  def check_changes
    if options[:article_id].present? && attribute_exists?('article.id')
      @changed_attributes['article'] = true
    end

    options[:changes].each_key do |key|
      next if !attribute_exists?("ticket.#{key}")

      @changed_attributes["ticket.#{key}"] = true
    end
  end

  def attribute_exists?(attribute, check_condition = @selector[:conditions])
    result = false
    check_condition.each do |condition|
      if condition.key?(:conditions)
        if attribute_exists?(attribute, condition[:conditions])
          result = true
        end
      elsif condition[:name] == attribute
        result = true
      end
    end
    result
  end

  def get
    raise 'NOT_IMPLEMENTED'
  end

  class InvalidCondition < StandardError
  end
end
