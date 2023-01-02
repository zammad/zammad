# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Attributes::User < CoreWorkflow::Attributes::Base

  def values
    if @attribute[:name] == 'owner_id' && @attributes.payload['class_name'] == 'Ticket'
      return ticket_owner_id_bulk if @attributes.payload['screen'] == 'overview_bulk'

      return ticket_owner_id
    end

    []
  end

  def group_agent_user_ids(group_id)
    @group_agent_user_ids ||= {}
    @group_agent_user_ids[group_id] ||= User.joins(', groups_users').where("users.id = groups_users.user_id AND groups_users.access = 'full' AND groups_users.group_id = ? AND users.id IN (?)", group_id, agent_user_ids).pluck(:id)
  end

  def group_agent_roles_ids(group_id)
    @group_agent_roles_ids ||= {}
    @group_agent_roles_ids[group_id] ||= Role.joins(', roles_groups').where("roles.id = roles_groups.role_id AND roles_groups.access = 'full' AND roles_groups.group_id = ? AND roles.id IN (?)", group_id, agent_role_ids).pluck(:id)
  end

  def agent_user_ids
    @agent_user_ids ||= User.joins(:roles).where(users: { active: true }).where('roles_users.role_id' => agent_role_ids).pluck(:id)
  end

  def agent_role_ids
    @agent_role_ids ||= Role.with_permissions('ticket.agent').pluck(:id)
  end

  def group_agent_role_user_ids(group_id)
    @group_agent_role_user_ids ||= {}
    @group_agent_role_user_ids[group_id] ||= User.joins(:roles).where(roles: { id: group_agent_roles_ids(group_id) }).pluck(:id)
  end

  def ticket_owner_id
    return [''] if @attributes.selected_only.group_id.blank?

    owner_ids = group_owner_ids
    return [''] if owner_ids.blank?

    owner_ids
  end

  def group_owner_ids
    user_ids = []

    # dont show system user in frontend but allow to reset it to 1 on update/create of the ticket
    if @attributes.payload['request_id'] == 'ChecksCoreWorkflow.validate_workflows'
      user_ids = [1]
    end

    User.where(id: group_owner_ids_user_ids, active: true).each do |user|
      user_ids << user.id
      assets(user)
    end

    user_ids
  end

  def group_owner_ids_user_ids
    group_agent_user_ids(@attributes.selected.group_id).concat(group_agent_role_user_ids(@attributes.selected.group_id)).uniq
  end

  def group_ids_bulk
    @group_ids_bulk ||= begin
      ticket_ids = String(@attributes.payload['params']['ticket_ids']).split(',').map(&:to_i)
      Ticket.distinct.where(id: ticket_ids).pluck(:group_id)
    end
  end

  def group_users_bulk
    @group_users_bulk ||= begin
      group_users_bulk_user_count.keys.select { |user| group_users_bulk_user_count[user] == group_ids_bulk.count }
    end
  end

  def group_users_bulk_user_count
    @group_users_bulk_user_count ||= begin
      user_count = {}
      group_ids_bulk.each do |group_id|
        User.where(id: group_agent_user_ids(group_id).concat(group_agent_role_user_ids(group_id)).uniq, active: true).each do |user|
          user_count[user] ||= 0
          user_count[user] += 1
        end
      end
      user_count
    end
  end

  def ticket_owner_id_bulk
    return group_owner_ids if @attributes.selected.group_id.present?

    return [''] if group_users_bulk.blank?

    group_users_bulk.each { |user| assets(user) }
    group_users_bulk.map(&:id)
  end

  def assets(user)
    return if @attributes.assets == false
    return if @attributes.assets[User.to_app_model] && @attributes.assets[User.to_app_model][user.id]

    @attributes.assets = user.assets(@attributes.assets)
  end
end
