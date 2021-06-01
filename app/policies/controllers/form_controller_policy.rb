# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::FormControllerPolicy < Controllers::ApplicationControllerPolicy

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

  def user_required?
    false
  end

  def enabled?
    Setting.get('form_ticket_create')
  end
end
