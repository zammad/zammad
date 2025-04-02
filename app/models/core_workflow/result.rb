# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Result
  include ::Mixin::HasBackends

  MAX_RERUN = 25

  attr_accessor :payload, :payload_backup, :user, :assets, :assets_in_result, :result, :rerun, :rerun_history, :form_updater, :restricted_fields

  def initialize(payload:, user:, assets: {}, assets_in_result: true, result: {}, form_updater: false)
    if payload.respond_to?(:permit!)
      payload = payload.permit!.to_h
    end

    raise ArgumentError, __("The required parameter 'payload->class_name' is missing.") if !payload['class_name']
    raise ArgumentError, __("The required parameter 'payload->screen' is missing.") if !payload['screen']

    @restricted_fields = {}
    @payload           = payload
    @payload_backup    = Marshal.load(Marshal.dump(payload))
    @user              = user
    @assets            = assets
    @assets_in_result  = assets_in_result
    @result            = result
    @form_updater      = form_updater
    @rerun             = false
    @rerun_history     = []
  end

  def attributes
    @attributes ||= CoreWorkflow::Attributes.new(result_object: self)
  end

  def workflows
    CoreWorkflow.active.object(payload['class_name'])
  end

  def set_default
    @rerun = false

    set_payload_body
    set_payload_customer_id_default

    @result[:restrict_values] = {}
    %i[request_id visibility mandatory readonly select fill_in eval matched_workflows rerun_count].each do |group|
      @result[group] = attributes.send(:"#{group}_default")
    end

    set_form_updater_default

    # restrict init defaults to make sure param values to removed if not allowed
    attributes.restrict_values_default.each do |field, values|

      # skip initial rerun to improve performance
      # priority e.g. would trigger a rerun because its not set yet
      # but we skip rerun here because the initial values have no logic which
      # are dependent on form changes
      run_backend_value('set_fixed_to', field, values, skip_rerun: true, skip_mark_restricted: true)
    end

    set_default_only_shown_if_selectable
  end

  def set_payload_body
    @payload['params']['body'] = @payload.dig('params', 'article', 'body')
  end

  def set_payload_customer_id_default
    return if !@payload['params']['customer_id'].nil?
    return if !@user
    return if !@user.permissions?('ticket.customer')
    return if @user.permissions?('ticket.agent')

    @payload['params']['customer_id'] = @user.id.to_s
  end

  def set_form_updater_default
    return if !form_updater

    @result[:all_options] = attributes.all_options_default
    @result[:historical_options] = attributes.historical_options_default
  end

  def set_default_only_shown_if_selectable

    # only_shown_if_selectable should not work on bulk feature
    return if @payload['screen'] == 'overview_bulk'

    auto_hide = {}

    attributes.auto_select_default.each do |field, state|
      result = run_backend_value('auto_select', field, state)
      next if result.compact.blank?

      auto_hide[field] = true
    end

    auto_hide.each do |field, state|
      run_backend_value('hide', field, state)
    end
  end

  def run
    set_default

    workflows.each do |workflow|
      condition = CoreWorkflow::Condition.new(result_object: self, workflow: workflow)
      next if !condition.match_all?

      run_workflow(workflow)
      run_custom(workflow, condition)
      match_workflow(workflow)

      break if workflow.stop_after_match
    end

    consider_rerun
  end

  def matches_selector?(selector:, check:)
    condition_object = CoreWorkflow::Condition.new(result_object: self)
    condition_object.check = check
    condition_object.condition_selector_match?(selector)
  end

  def run_workflow(workflow)
    Array(workflow.perform).each do |field, config|
      run_backend(field, config)
    end
  end

  def run_custom(workflow, condition)
    Array(workflow.perform.dig('custom.module', 'execute')).each do |module_path|
      custom_module = module_path.constantize.new(condition_object: condition, result_object: self)
      custom_module.perform
    end
  end

  def run_backend(field, perform_config, skip_rerun: false, skip_mark_restricted: false)
    Array(perform_config['operator']).map do |backend|
      "CoreWorkflow::Result::#{backend.classify}"
        .constantize
        .new(result_object: self, field: field, perform_config: perform_config, skip_rerun: skip_rerun, skip_mark_restricted: skip_mark_restricted)
        .run
    end
  end

  def run_backend_value(backend, field, value, skip_rerun: false, skip_mark_restricted: false)
    perform_config = {
      'operator' => backend,
      backend    => value,
    }

    run_backend(field, perform_config, skip_rerun: skip_rerun, skip_mark_restricted: skip_mark_restricted)
  end

  def change_flags(flags)
    @result[:flags] ||= {}
    @result[:flags] = @result[:flags].merge(flags)
  end

  def match_workflow(workflow)
    @result[:matched_workflows] |= Array(workflow.id)
  end

  def assets_in_result?
    return false if assets == false
    return false if !@assets_in_result

    @result[:assets] = assets

    true
  end

  def workflow_restricted_fields
    @workflow_restricted_fields ||= begin
      result = []
      workflows.each do |workflow|
        fields = workflow.perform.each_with_object([]) do |(key, value), result_inner|
          next if %w[select remove_option set_fixed_to add_option].exclude?(value['operator'])

          result_inner << key.split('.')[-1]
        end

        result |= fields
      end
      result
    end
  end

  def filter_restrict_values
    @result[:restrict_values].select! do |field, _values|
      attribute = attributes.object_elements_hash[field]
      next if attribute && workflow_restricted_fields.exclude?(field) && !@restricted_fields[field] && !attributes.attribute_options_relation?(attribute) && !attributes.attribute_filter?(attribute)

      true
    end
  end

  def rerun_loop?
    return false if rerun_history.size < 3

    rerun_history.last(3).uniq.size != 3
  end

  def consider_rerun
    @rerun_history << Marshal.load(Marshal.dump(@result.except(:rerun_count)))
    if @rerun && @result[:rerun_count] < MAX_RERUN && !rerun_loop?
      @result[:rerun_count] += 1
      return run
    end

    filter_restrict_values if !@form_updater

    assets_in_result?

    @result
  end
end
