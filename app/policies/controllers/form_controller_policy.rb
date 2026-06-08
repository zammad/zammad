# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::FormControllerPolicy < Controllers::ApplicationControllerPolicy
  USER_REQUIRED = false

  def configuration?
    authorized?
  end

  def submit?
    authorized?
  end

  def test?
    record.params[:test] && user&.permissions?('admin.channel_formular')
  end

  private

  def authorized?
    test? || enabled?
  end

  def enabled?
    Setting.get('form_ticket_create')
  end
end
