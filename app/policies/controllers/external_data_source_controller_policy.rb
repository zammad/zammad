# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Controllers::ExternalDataSourceControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! :preview, to: 'admin.object'

  def fetch?
    ExternalDataSourcePolicy
      .new(user, record.params[:object])
      .fetch?
  end
end
