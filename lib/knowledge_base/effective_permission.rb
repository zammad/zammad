# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase
  class EffectivePermission
    def initialize(user, object)
      @user   = user
      @object = object
    end

    def access_effective
      return 'none' if !@user

      @user.roles.reduce('none') do |memo, role|
        access = access_role_effective(role)

        return 'editor' if access == 'editor'

        access_role_reducer(memo, access)
      end
    end

    private

    def access_role_reducer(memo, access)
      case access
      when 'reader'
        'reader'
      when 'public_reader'
        memo == 'reader' ? memo : access
      when 'none'
        memo
      end
    end

    def permissions
      @permissions ||= @object.permissions_effective
    end

    def access_role_effective(role)
      permission = permissions.find { |elem| elem.role == role }

      return default_role_access(role) if !permission

      calculate_role(role, permission)
    end

    def calculate_role(role, permission)
      if permission.access == 'editor' && role.with_permission?('knowledge_base.editor')
        'editor'
      elsif %w[editor reader].include?(permission.access) && role.with_permission?(%w[knowledge_base.editor knowledge_base.reader])
        'reader'
      elsif @object.public_content?
        'public_reader'
      else
        'none'
      end
    end

    def default_role_access(role)
      if role.with_permission?('knowledge_base.editor')
        'editor'
      elsif role.with_permission?('knowledge_base.reader')
        'reader'
      else
        'none'
      end
    end
  end
end
