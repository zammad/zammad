# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Assigns roles on third-party login based on a claim (OpenID Connect) or an attribute (SAML)
# of the identity provider. Once configured, the identity provider is the leading source:
# all roles of the user are replaced on every login, like LDAP does with its group role map.
class Authorization::RoleMapping
  PROVIDERS            = %w[saml openid_connect].freeze
  UNMATCHED_BEHAVIOURS = %w[signup_roles deny].freeze
  ADMIN_PERMISSIONS    = %w[admin admin.user].freeze

  # Key of the role mapping in the credentials of a provider, which must not be passed on to OmniAuth.
  CREDENTIALS_KEY = 'role_mapping'.freeze

  attr_reader :auth_hash, :provider, :config

  def self.config(provider)
    return {} if PROVIDERS.exclude?(provider)

    Setting.get("auth_#{provider}_credentials")&.dig(CREDENTIALS_KEY).presence || {}
  end

  def initialize(auth_hash)
    @auth_hash = auth_hash
    @provider  = auth_hash['provider'].to_s
    @config    = self.class.config(provider)
  end

  def enabled?
    config['attribute'].present? && config['map'].present?
  end

  # Has to run before the user is looked up, so a denied login neither creates nor links an account.
  def verify!
    return if !enabled?
    return if config['unmatched'] != 'deny'
    return if mapped_role_ids.present?

    Rails.logger.info { "Denied #{provider} login of '#{auth_hash['uid']}': no role is mapped for the values #{claim_values.inspect} of '#{config['attribute']}'." }

    raise Authorization::Provider::AccountError, __('Your identity provider does not grant you access to this system. Please contact your administrator.')
  end

  def apply(user)
    return if !enabled?
    return if ldap_managed?(user)

    role_ids = mapped_role_ids.presence || Role.signup_role_ids
    role_ids |= retained_admin_role_ids(user, role_ids)
    previous_role_ids = user.role_ids
    return if role_ids.sort == previous_role_ids.sort

    UserInfo.with_user_id(user.id) do
      User.transaction(requires_new: true) { user.role_ids = role_ids }
    end

    Rails.logger.debug { "Changed the roles of user '#{user.login}' via #{provider} from #{previous_role_ids.sort.inspect} to #{role_ids.sort.inspect}, #{mapping_source}." }
  # e.g. the agent limit or conflicting roles, which must not abort the login
  rescue Exceptions::UnprocessableContent, RuntimeError => e
    user.reload
    Rails.logger.error { "Unable to assign the roles #{role_ids.inspect} from #{provider} to user '#{user.login}', keeping the current ones: #{e.message}" }
  end

  private

  def mapped_role_ids
    @mapped_role_ids ||= begin
      role_ids = claim_values.flat_map { |value| Array.wrap(config['map'][value]) }
      Role.where(id: role_ids.map(&:to_i)).ids
    end
  end

  def mapping_source
    return "mapped from the values #{claim_values.inspect} of '#{config['attribute']}'" if mapped_role_ids.present?

    "no role is mapped for the values #{claim_values.inspect} of '#{config['attribute']}', assigned the signup roles"
  end

  def claim_values
    @claim_values ||= Array.wrap(raw_claim_value).flatten.compact_blank.map(&:to_s)
  end

  # SAML attribute names are often URIs containing dots, while OpenID Connect
  # claims can be nested (e.g. "resource_access.zammad.roles").
  def raw_claim_value
    raw_info = auth_hash.dig('extra', 'raw_info')
    return if raw_info.blank?

    # OneLogin::RubySaml::Attributes#[] only returns the first value of an attribute.
    return raw_info.multi(config['attribute']) if raw_info.respond_to?(:multi)

    config['attribute'].split('.').reduce(raw_info) do |node, key|
      break if !node.is_a?(Hash)

      node[key]
    end
  end

  # LDAP keeps the roles of its users if its source maps groups to roles,
  # both would overwrite each other otherwise.
  def ldap_managed?(user)
    return false if !Setting.get('ldap_integration')

    source_id = user.source.to_s[%r{\ALdap::(\d+)\z}, 1]
    return false if source_id.nil?

    return false if LdapSource.active.find_by(id: source_id)&.preferences&.dig(:group_role_map).blank?

    Rails.logger.info { "Skipped the #{provider} role mapping for user '#{user.login}', the roles are managed by LDAP." }
    true
  end

  # Removing an admin role from the last admin raises in User#last_admin_check_by_role,
  # which would abort the login instead of just keeping the role.
  def retained_admin_role_ids(user, role_ids)
    admin_role_ids = (user.role_ids - role_ids).select { |role_id| Role.find(role_id).with_permission?(ADMIN_PERMISSIONS) }
    return [] if admin_role_ids.empty?
    return [] if User.admin_user_exists?(except_user_id: user.id)

    Rails.logger.warn { "Kept the admin roles #{admin_role_ids.inspect} of user '#{user.login}', it is the last admin." }
    admin_role_ids
  end
end
