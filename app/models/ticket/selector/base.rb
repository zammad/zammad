# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Ticket::Selector::Base
  attr_accessor :selector, :options

  def initialize(selector:, options:)
    if selector.respond_to?(:permit!)
      selector = selector.permit!.to_h
    end

    @selector                   = Marshal.load(Marshal.dump(selector)).deep_symbolize_keys
    @options                    = options
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

  def set_static_conditions # rubocop:disable Metrics/AbcSize
    return if %i[ticket_id article_id exclude_merged].none? { |key| options[key].present? }

    new_selector = {
      operator:   'AND',
      conditions: []
    }

    if options[:ticket_id].present?
      new_selector[:conditions] << {
        name:     'ticket.id',
        operator: 'is',
        value:    options[:ticket_id]
      }
    end

    if options[:article_id].present?
      new_selector[:conditions] << {
        name:     'article.id',
        operator: 'is',
        value:    options[:article_id]
      }
    end

    if options[:exclude_merged].present?
      new_selector[:conditions] << {
        name:     'ticket_state.name',
        operator: 'is not',
        value:    Ticket::StateType.find_by(name: 'merged').states.pluck(:name),
      }
    end

    if @selector[:conditions].present?
      new_selector[:conditions] << @selector
    end

    @selector = new_selector
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

  def valid?
    ticket_count, _tickets = self.class.new(selector: selector, options: options.merge(limit: 1, execution_time: true, ticket_id: 1)).get
    return if ticket_count.nil?

    true
  rescue
    nil
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
