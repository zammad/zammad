# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::User::Roles < Sequencer::Unit::Common::Provider::Named
  uses :resource, :initiator

  private

  def roles
    return admin if initiator

    map_roles
  end

  def map_roles
    return send(kayako_role) if kayako_role && respond_to?(kayako_role, true)

    logger.debug "Unknown mapping for role '#{resource['role']['type']}' (method: #{kayako_role})"

    customer
  end

  def kayako_role
    @kayako_role ||= resource['role']&.fetch('type')&.downcase
  end

  def customer
    [role_customer]
  end

  def collaborators
    agent
  end

  def agent
    [role_agent]
  end

  def owner
    admin
  end

  def admin
    [role_admin, role_agent]
  end

  def role_admin
    @role_admin ||= lookup('Admin')
  end

  def role_agent
    @role_agent ||= lookup('Agent')
  end

  def role_customer
    @role_customer ||= lookup('Customer')
  end

  def lookup(role_name)
    ::Role.lookup(name: role_name)
  end
end
