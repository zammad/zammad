# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::System::CheckSetup < Service::Base

  attr_reader :status, :type

  STATES = %w[new automated in_progress done].freeze
  TYPES = %w[auto manual import].freeze

  def self.new?
    setup = new
    setup.execute

    setup.status == 'new'
  end

  def self.new!
    raise SystemSetupError, __('The system setup cannot be started, because there is another one running or it was completed before.') if !new?
  end

  def self.done?
    setup = new
    setup.execute

    setup.status == 'done'
  end

  def self.done!
    raise SystemSetupError, __('This operation cannot be continued, because the system set-up was not completed yet.') if !done?
  end

  def execute
    if Setting.get('import_mode')
      @status = 'in_progress'
      @type = 'import'
      return
    end

    if setup_done!
      @status = 'done'
      return
    end

    if Service::ExecuteLockedBlock.locked?('Zammad::System::Setup')
      @status = 'in_progress'
      @type = AutoWizard.enabled? ? 'auto' : 'manual'
      return
    end

    if AutoWizard.enabled?
      @status = 'automated'
      return
    end

    @status = 'new'
  end

  private

  def setup_done!
    is_done = Setting.get('system_init_done')
    has_admin = User.all.any? { |user| user.role?('Admin') && user.active? && user.id != 1 }

    if !is_done && has_admin
      Rails.logger.warn('The system setup is not marked as done, but at least one admin user is existing. Marking system setup as done.')
      Setting.set('system_init_done', true)
      return true
    end

    if is_done && !has_admin
      Setting.set('system_init_done', false)
      raise SystemSetupError, __('The system setup is marked as done, but no admin user is existing. Please run the system setup again.')
    end

    if is_done && has_admin
      return true
    end

    false
  end

  class SystemSetupError < StandardError; end
end
