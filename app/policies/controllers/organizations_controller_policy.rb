# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::OrganizationsControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! :import_example, to: 'admin.organization'
  permit! :import_start, to: 'admin.user'
  permit! %i[create update destroy search history], to: ['ticket.agent', 'admin.organization']

  def show?
    return true if user.permissions?(['ticket.agent', 'admin.organization'])

    record.params[:id].to_i == user.organization_id
  end
end
