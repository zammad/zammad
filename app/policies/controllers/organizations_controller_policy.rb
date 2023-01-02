# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Controllers::OrganizationsControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! :import_example, to: 'admin.organization'
  permit! :import_start, to: 'admin.user'
  permit! %i[create update destroy search history], to: ['ticket.agent', 'admin.organization']

  def show?
    return true if user.permissions?(['ticket.agent', 'admin.organization'])

    user.organization_id?(record.params[:id].to_i)
  end
end
