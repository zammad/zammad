# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Controllers::ApplicationControllerPolicy < ApplicationPolicy
  class_attribute(:action_permissions_map, default: {})

  def self.inherited(subclass)
    super

    subclass.action_permissions_map = action_permissions_map.deep_dup
  end

  def self.default_permit!(permissions)
    action_permissions_map.default = permissions
  end

  def self.permit!(actions, to:)
    Array(actions).each do |action|
      action_permissions_map[:"#{action}?"] = to
    end
  end

  def method_missing(missing_method, *)
    case (permission = action_permissions_map[missing_method])
    when String, Array
      user.permissions!(permission)
    when Proc
      user.permissions!(instance_exec(&permission))
    else
      super
    end
  rescue Exceptions::Forbidden => e
    not_authorized(e)
  end

  def respond_to_missing?(missing_method)
    action_permissions_map[missing_method] || super
  end

end
