# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Result
  include ::Mixin::HasBackends

  attr_accessor :payload, :user, :assets, :assets_in_result, :result, :rerun, :form_updater

  def initialize(payload:, user:, assets: {}, assets_in_result: true, result: {}, form_updater: false)
    raise ArgumentError, __("The required parameter 'payload->class_name' is missing.") if !payload['class_name']
    raise ArgumentError, __("The required parameter 'payload->screen' is missing.") if !payload['screen']

    @payload          = payload
    @user             = user
    @assets           = assets
    @assets_in_result = assets_in_result
    @result           = result
    @form_updater     = form_updater
    @rerun            = false
  end

  def attributes
    @attributes ||= CoreWorkflow::Attributes.new(result_object: self)
  end

  def workflows
    CoreWorkflow.active.object(payload['class_name'])
  end

  def set_default
    @rerun = false

    @result[:restrict_values] = {}
    %i[request_id visibility mandatory readonly select fill_in eval matched_workflows rerun_count].each do |group|
      @result[group] = attributes.send(:"#{group}_default")
    end

    if form_updater
      @result[:all_options] = attributes.all_options_default
    end

    # restrict init defaults to make sure param values to removed if not allowed
    attributes.restrict_values_default.each do |field, values|

      # skip initial rerun to improve performance
      # priority e.g. would trigger a rerun because its not set yet
      # but we skip rerun here because the initial values have no logic which
      # are dependent on form changes
      run_backend_value('set_fixed_to', field, values, skip_rerun: true)
    end

    set_default_only_shown_if_selectable
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

  def run_backend(field, perform_config, skip_rerun: false)
    result = []
    Array(perform_config['operator']).each do |backend|
      result << "CoreWorkflow::Result::#{backend.classify}".constantize.new(result_object: self, field: field, perform_config: perform_config, skip_rerun: skip_rerun).run
    end
    result
  end

  def run_backend_value(backend, field, value, skip_rerun: false)
    perform_config = {
      'operator' => backend,
      backend    => value,
    }

    run_backend(field, perform_config, skip_rerun: skip_rerun)
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

  def consider_rerun
    if @rerun && @result[:rerun_count] < 25
      @result[:rerun_count] += 1
      return run
    end

    assets_in_result?

    @result
  end
end
