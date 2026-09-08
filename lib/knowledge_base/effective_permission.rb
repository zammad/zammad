# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase
  class EffectivePermission
    def initialize(user, object)
      @user   = user
      @object = object
    end

    # The access a role holds by virtue of its own global permission, i.e. with nothing stored for
    #   it anywhere. Also what a granular selection has to differ from to be worth storing.
    def self.default_role_access(role)
      if role.with_permission?('knowledge_base.editor')
        'editor'
      elsif role.with_permission?('knowledge_base.reader')
        'reader'
      else
        'none'
      end
    end

    # Only the active roles grant anything: a deactivated role must contribute nothing, the same
    #   rule User::Permissions applies with `where(roles: { active: true })`, and what makes
    #   `user.permissions?('knowledge_base.editor')` and KnowledgeBase.access_for_user already
    #   agree that such a user has no knowledge base access.
    #
    # Deliberately not pushed down into Role#with_permission?: that is a predicate about the role
    #   itself, and callers like Service::KnowledgeBase::Concerns::AppliesPermissions legitimately
    #   ask it of an inactive role while rendering the admin interface. The filter belongs here,
    #   where the role list becomes a user-level authorization decision.
    #
    # KnowledgeBase::AccessibleCategories.cache_key fingerprints the same list, so the two have to
    #   be kept in step: keying on anything wider would keep serving the access a role granted
    #   while it was still active.
    def access_effective
      return 'none' if !@user

      @user.roles.where(active: true).reduce('none') do |memo, role|
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
      self.class.default_role_access(role)
    end
  end
end
