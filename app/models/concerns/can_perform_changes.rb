# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

##
# A mixin for ActiveRecord models that enables the possibilitty to perform actions.
#
# It's normally used to perform actions for the following functionalities: `Trigger`, `Job`, `Macro`.
#
# With `available_perform_change_actions` you need to define which action is supported from the model.
# It's also possible to run a `pre_execution` for a specifc model, to prepare special data for the actions (e.g. fetch
# the article in the ticket context, when a `article_id` is present inside the `context_data`).
#
# The actions can run in different phases: `initial`, `before_save`, `after_save`. The initial phase could
# also manipulate the actions for the other phases (e.g. the delete action will skip the attribute updates).
#
# In the ticket context you can see how it's possible to add custom model actions and also to extend the
# action layer in general (e.g. usage of `pre_execution`)
#
# @example
#
# class User < ApplicationRecord
#   include CanPerformChanges
#
#   available_perform_change_actions :data_privacy_deletion_task, :attribute_updates
# end
#
# user.perform_changes(trigger, 'trigger', item, current_user_id)
#
# user.perform_changes(job, 'job', item, current_user_id)
#
module CanPerformChanges
  extend ActiveSupport::Concern

  # Perform changes on self according to perform rules
  #
  # @param performable [Trigger, Macro, Job] object
  # @param origin [String] name of the object to be performed
  # @param context_data [Hash]
  # @param user_id [Integer] to run as
  # @param activator_type [String] activator of time-based triggers reminder_reached, escalation, null otherwise
  # @yield [object, save_needed] alternative way to save object during application
  # @yieldparam [object, [Ticket, User, Organization] object performed on
  # @yieldparam [save_needed, [Boolean] if changes were applied that should be saved
  def perform_changes(performable, origin, context_data = nil, user_id = nil, activator_type: nil, &)
    return if !execute?(performable, activator_type)

    perform_changes_data = {
      performable:  performable,
      origin:       origin,
      context_data: context_data,
      user_id:      user_id,
    }

    Rails.logger.debug { "Perform #{origin} #{performable.perform.inspect} on #{self.class.name}.find(#{id})" }

    try(:pre_execute, perform_changes_data)

    execute(perform_changes_data, &)

    performable.try(:performed_on, self, activator_type:)

    true
  end

  private

  class_methods do
    # Defines the actions that are performed for the object.
    def available_perform_change_actions(*actions)
      @available_perform_change_actions ||= actions
    end
  end

  def execute?(performable, activator_type)
    performable_on_result = performable.try(:performable_on?, self, activator_type:)

    # performable_on_result can be nil, false or true
    return false if performable_on_result.eql?(false)

    true
  end

  def execute(perform_changes_data)
    prepared_actions = prepare_actions(perform_changes_data)

    raise "The given #{perform_changes_data[:origin]} contains no valid actions, stopping!" if prepared_actions.all? { |_, v| v.blank? }

    prepared_actions[:initial].each do |instance|
      instance.execute(prepared_actions)
    end

    save_needed = execute_before_save(prepared_actions[:before_save])

    if block_given?
      yield(self, save_needed)
    elsif save_needed
      save!
    end

    prepared_actions[:after_save]&.each(&:execute)

    true
  end

  def execute_before_save(before_save_actions)
    return if !before_save_actions

    before_save_actions.reduce(false) do |memo, elem|
      changed = elem.execute

      memo || changed
    end
  end

  def prepare_actions(perform_changes_data)
    action_checks = %w[notification additional_object object attribute_update]
    actions = {}

    perform_changes_data[:performable].perform.each do |attribute, action_value|
      (object_name, object_key) = attribute.split('.', 2)

      action = nil
      action_checks.each do |key|
        action = send(:"#{key}_action", object_name, object_key, action_value, actions)
        break if action
      end

      next if action.nil? || self.class.available_perform_change_actions.exclude?(action[:name])

      actions[action[:name]] = action[:value]
    end

    prepared_actions = {
      initial:     [],
      before_save: [],
      after_save:  [],
    }

    actions.each do |action, value|
      instance = create_action_instance(action, value, perform_changes_data)

      prepared_actions[instance.class.phase].push(instance)
    end

    prepared_actions
  end

  def notification_action(object_name, object_key, action_value, _prepared_actions)
    return if !object_name.eql?('notification')

    { name: :"notification_#{object_key}", value: action_value }
  end

  def additional_object_action(*)
    return if !respond_to?(:additional_object_actions)

    additional_object_action(*)
  end

  def object_action(object_name, object_key, action_value, _prepared_actions)
    if self.class.name.downcase.eql?(object_name) && object_key.eql?('action')
      return { name: action_value['value'].to_sym, value: true }
    end

    nil
  end

  def attribute_update_action(object_name, object_key, action_value, prepared_actions)
    return if !self.class.name.downcase.eql?(object_name)

    prepared_actions[:attribute_updates] ||= {}
    prepared_actions[:attribute_updates][object_key] = action_value

    { name: :attribute_updates, value: prepared_actions[:attribute_updates] }
  end

  def create_action_instance(action, data, perform_changes_data)
    PerformChanges::Action.action_lookup[action].new(self, data, perform_changes_data)
  end
end
