# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class User < ApplicationModel
  include CanBeImported
  include HasActivityStreamLog
  include ChecksClientNotification
  include HasHistory
  include HasSearchIndexBackend
  include CanSelector
  include CanCsvImport
  include ChecksHtmlSanitized
  include HasGroups
  include HasRoles
  include HasObjectManagerAttributes
  include HasTaskbars
  include HasTwoFactor
  include CanSelector
  include CanPerformChanges
  include User::Assets
  include User::Avatar
  include User::Search
  include User::SearchIndex
  include User::TouchesOrganization
  include User::TriggersSubscriptions
  include User::PerformsGeoLookup
  include User::UpdatesTicketOrganization
  include User::OutOfOffice
  include User::Permissions

  has_and_belongs_to_many :organizations,          after_add: %i[cache_update create_organization_add_history], after_remove: %i[cache_update create_organization_remove_history], class_name: 'Organization'
  has_and_belongs_to_many :overviews,              dependent: :nullify
  has_many                :tokens,                 after_add: :cache_update, after_remove: :cache_update, dependent: :destroy
  has_many                :authorizations,         after_add: :cache_update, after_remove: :cache_update, dependent: :destroy
  has_many                :online_notifications,   dependent: :destroy
  has_many                :taskbars,               dependent: :destroy
  has_many                :user_devices,           dependent: :destroy
  has_one                 :chat_agent_created_by,  class_name: 'Chat::Agent', foreign_key: :created_by_id, dependent: :destroy, inverse_of: :created_by
  has_one                 :chat_agent_updated_by,  class_name: 'Chat::Agent', foreign_key: :updated_by_id, dependent: :destroy, inverse_of: :updated_by
  has_many                :chat_sessions,          class_name: 'Chat::Session', dependent: :destroy
  has_many                :mentions,               dependent: :destroy
  has_many                :cti_caller_ids,         class_name: 'Cti::CallerId', dependent: :destroy
  has_many                :customer_tickets,       class_name: 'Ticket', foreign_key: :customer_id, dependent: :destroy, inverse_of: :customer
  has_many                :owner_tickets,          class_name: 'Ticket', foreign_key: :owner_id, inverse_of: :owner
  has_many                :overview_sortings,      dependent: :destroy
  has_many                :created_recent_views,   class_name: 'RecentView', foreign_key: :created_by_id, dependent: :destroy, inverse_of: :created_by
  has_many                :data_privacy_tasks,     as: :deletable
  belongs_to              :organization,           inverse_of: :members, optional: true

  before_validation :check_name, :check_email, :check_login, :ensure_password, :ensure_roles, :ensure_organizations, :ensure_organizations_limit
  before_validation :check_mail_delivery_failed, on: :update
  before_save       :ensure_notification_preferences, if: :reset_notification_config_before_save
  before_create     :validate_preferences, :domain_based_assignment, :set_locale
  before_update     :validate_preferences, :reset_login_failed_after_password_change, :validate_agent_limit_by_attributes, :last_admin_check_by_attribute
  before_destroy    :destroy_longer_required_objects, :destroy_move_dependency_ownership
  after_commit      :update_caller_id

  validate :ensure_identifier, :ensure_email
  validate :ensure_uniq_email, unless: :skip_ensure_uniq_email

  available_perform_change_actions :data_privacy_deletion_task, :attribute_updates

  # workflow checks should run after before_create and before_update callbacks
  # the transaction dispatcher must be run after the workflow checks!
  include ChecksCoreWorkflow
  include HasTransactionDispatcher

  core_workflow_screens 'create', 'edit', 'invite_agent'
  core_workflow_admin_screens 'create', 'edit'

  taskbar_entities 'UserProfile'

  store :preferences

  association_attributes_ignored :online_notifications,
                                 :templates,
                                 :taskbars,
                                 :user_devices,
                                 :chat_sessions,
                                 :cti_caller_ids,
                                 :text_modules,
                                 :customer_tickets,
                                 :owner_tickets,
                                 :created_recent_views,
                                 :chat_agents,
                                 :data_privacy_tasks,
                                 :overviews,
                                 :mentions

  activity_stream_permission 'admin.user'

  activity_stream_attributes_ignored :last_login,
                                     :login_failed,
                                     :image,
                                     :image_source,
                                     :preferences

  history_attributes_ignored :password,
                             :last_login,
                             :image,
                             :image_source,
                             :preferences

  search_index_attributes_ignored :password,
                                  :image,
                                  :image_source,
                                  :source,
                                  :login_failed

  csv_object_ids_ignored 1

  csv_attributes_ignored :password,
                         :login_failed,
                         :source,
                         :image_source,
                         :image,
                         :authorizations,
                         :groups,
                         :user_groups,
                         :two_factor_preferences,
                         :chat_agent_created_by,
                         :chat_agent_updated_by,
                         :overview_sortings

  validates :note, length: { maximum: 5000 }
  sanitized_html :note, no_images: true

  def ignore_search_indexing?(_action)
    # ignore internal user
    return true if id == 1

    false
  end

=begin

fullname of user

  user = User.find(123)
  result = user.fullname

returns

  result = "Bob Smith"

=end

  def fullname(email_fallback: true, recipient_line: false)
    name = "#{firstname} #{lastname}".strip

    if name.blank? && email.present? && email_fallback
      return email
    elsif recipient_line
      begin
        return Channel::EmailBuild.recipient_line(name, email)
      rescue
        return email
      end
    end

    return name if name.present?

    %w[phone mobile].each do |item|
      next if self[item].blank?

      return self[item]
    end

    name
  end

=begin

longname of user

  user = User.find(123)
  result = user.longname

returns

  result = "Bob Smith"

  or with org

  result = "Bob Smith (Org ABC)"

=end

  def longname
    name = fullname
    if organization_id
      organization = Organization.lookup(id: organization_id)
      if organization
        name += " (#{organization.name})"
      end
    end
    name
  end

=begin

check if user is in role

  user = User.find(123)
  result = user.role?('Customer')

  result = user.role?(['Agent', 'Admin'])

returns

  result = true|false

=end

  def role?(role_name)
    roles.where(name: role_name).any?
  end

=begin

get users activity stream

  user = User.find(123)
  result = user.activity_stream(20)

returns

  result = [
    {
      id: 2,
      o_id: 2,
      created_by_id: 3,
      created_at: '2013-09-28 00:57:21',
      object: "User",
      type: "created",
    },
    {
      id: 2,
      o_id: 2,
      created_by_id: 3,
      created_at: '2013-09-28 00:59:21',
      object: "User",
      type: "updated",
    },
  ]

=end

  def activity_stream(limit, fulldata = false)
    stream = ActivityStream.list(self, limit)
    return stream if !fulldata

    # get related objects
    assets = {}
    stream.each do |item|
      assets = item.assets(assets)
    end

    {
      stream: stream,
      assets: assets,
    }
  end

=begin

tries to find the matching instance by the given identifier. Currently email and login is supported.

  user = User.indentify('User123')

  # or

  user = User.indentify('user-123@example.com')

returns

  # User instance
  user.login # 'user123'

=end

  def self.identify(identifier)
    return if identifier.blank?

    # try to find user based on login
    user = User.find_by(login: identifier.downcase)
    return user if user

    # try second lookup with email
    User.find_by(email: identifier.downcase)
  end

=begin

create user from from omni auth hash

  result = User.create_from_hash!(hash)

returns

  result = user_model # user model if create was successfully

=end

  def self.create_from_hash!(hash)

    url = ''
    hash['info']['urls']&.each_value do |local_url|
      next if local_url.blank?

      url = local_url
    end
    begin
      data = {
        login:         hash['info']['nickname'] || hash['uid'],
        firstname:     hash['info']['name'] || hash['info']['display_name'],
        email:         hash['info']['email'],
        image_source:  hash['info']['image'],
        web:           url,
        address:       hash['info']['location'],
        note:          hash['info']['description'],
        source:        hash['provider'],
        role_ids:      Role.signup_role_ids,
        updated_by_id: 1,
        created_by_id: 1,
      }
      if hash['info']['first_name'].present? && hash['info']['last_name'].present?
        data[:firstname] = hash['info']['first_name']
        data[:lastname] = hash['info']['last_name']
      end
      create!(data)
    rescue => e
      logger.error e
      raise Exceptions::UnprocessableEntity, e.message
    end
  end

  # Find a user by mobile number, either directly or by number variants stored in the Cti::CallerIds.
  def self.by_mobile(number:)
    direct_lookup = User.where(mobile: number).reorder(:updated_at).first
    return direct_lookup if direct_lookup

    cti_lookup = Cti::CallerId.lookup(number.delete('+')).find { |id| id.level == 'known' && id.object == 'User' }
    User.find_by(id: cti_lookup.o_id) if cti_lookup
  end

=begin

generate new token for reset password

  result = User.password_reset_new_token(username)

returns

  result = {
    token: token,
    user: user,
  }

=end

  def self.password_reset_new_token(username)
    return if username.blank?

    # try to find user based on login
    user = User.find_by(login: username.downcase.strip, active: true)

    # try second lookup with email
    user ||= User.find_by(email: username.downcase.strip, active: true)

    return if !user || user.email.blank?

    # Discard any possible previous tokens for safety reasons.
    Token.where(action: 'PasswordReset', user_id: user.id).destroy_all

    {
      token: Token.create(action: 'PasswordReset', user_id: user.id, persistent: false),
      user:  user,
    }
  end

=begin

returns the User instance for a given password token if found

  result = User.by_reset_token(token)

returns

  result = user_model # user_model if token was verified

=end

  def self.by_reset_token(token)
    Token.check(action: 'PasswordReset', token: token)
  end

=begin

reset password with token and set new password

  result = User.password_reset_via_token(token,password)

returns

  result = user_model # user_model if token was verified

=end

  def self.password_reset_via_token(token, password)

    # check token
    user = by_reset_token(token)
    return if !user

    # reset password
    user.update!(password: password, verified: true)

    # delete token
    Token.find_by(action: 'PasswordReset', token: token).destroy
    user
  end

  def self.admin_password_auth_new_token(username)
    return if username.blank?

    # try to find user based on login
    user = User.find_by(login: username.downcase.strip, active: true)

    # try second lookup with email
    user ||= User.find_by(email: username.downcase.strip, active: true)

    return if !user || !user.email
    return if !user.permissions?('admin.*')

    # Discard any possible previous tokens for safety reasons.
    Token.where(action: 'AdminAuth', user_id: user.id).destroy_all

    {
      token: Token.create(action: 'AdminAuth', user_id: user.id, persistent: false),
      user:  user,
    }
  end

  def self.admin_password_auth_via_token(token)
    user = Token.check(action: 'AdminAuth', token: token)
    return if !user

    Token.find_by(action: 'AdminAuth', token: token).destroy

    user
  end

=begin

update last login date and reset login_failed (is automatically done by auth and sso backend)

  user = User.find(123)
  result = user.update_last_login

returns

  result = new_user_model

=end

  def update_last_login
    # reduce DB/ES load by updating last_login every 10 minutes only
    if !last_login || last_login < 10.minutes.ago
      self.last_login = Time.zone.now
    end

    # reset login failed
    self.login_failed = 0

    save
  end

=begin

generate new token for signup

  result = User.signup_new_token(user) # or email

returns

  result = {
    token: token,
    user: user,
  }

=end

  def self.signup_new_token(user)
    return if !user
    return if !user.email

    # Discard any possible previous tokens for safety reasons.
    Token.where(action: 'Signup', user_id: user.id).destroy_all

    # generate token
    token = Token.create(action: 'Signup', user_id: user.id)

    {
      token: token,
      user:  user,
    }
  end

=begin

verify signup with token

  result = User.signup_verify_via_token(token, user)

returns

  result = user_model # user_model if token was verified

=end

  def self.signup_verify_via_token(token, user = nil)

    # check token
    local_user = Token.check(action: 'Signup', token: token)
    return if !local_user

    # if requested user is different to current user
    return if user && local_user.id != user.id

    # set verified
    local_user.update!(verified: true)

    # delete token
    Token.find_by(action: 'Signup', token: token).destroy
    local_user
  end

=begin

merge two users to one

  user = User.find(123)
  result = user.merge(user_id_of_duplicate_user)

returns

  result = new_user_model

=end

  def merge(user_id_of_duplicate_user)

    # Raise an exception if the user is not found (?)
    #
    # (This line used to contain a useless variable assignment,
    # and was changed to satisfy the linter.
    # We're not certain of its original intention,
    # so the User.find call has been kept
    # to prevent any unexpected regressions.)
    User.find(user_id_of_duplicate_user)

    # mentions can not merged easily because the new user could have mentioned
    # the same ticket so we delete duplicates beforehand
    Mention.where(user_id: user_id_of_duplicate_user).find_each do |mention|
      if Mention.exists?(mentionable: mention.mentionable, user_id: id)
        mention.destroy
      else
        mention.update(user_id: id)
      end
    end

    # merge missing attributes
    Models.merge('User', id, user_id_of_duplicate_user)

    true
  end

=begin

list of active users in role

  result = User.of_role('Agent', group_ids)

  result = User.of_role(['Agent', 'Admin'])

returns

  result = [user1, user2]

=end

  def self.of_role(role, group_ids = nil)
    roles_ids = Role.where(active: true, name: role).map(&:id)
    if !group_ids
      return User.where(active: true).joins(:roles_users).where('roles_users.role_id' => roles_ids).reorder('users.updated_at DESC')
    end

    User.where(active: true)
        .joins(:roles_users)
        .joins(:users_groups)
        .where('roles_users.role_id IN (?) AND users_groups.group_ids IN (?)', roles_ids, group_ids).reorder('users.updated_at DESC')
  end

  # Reset agent notification preferences
  # Non-agent cannot receive notifications, thus notifications reset
  #
  # @option user [User] to reset preferences
  def self.reset_notifications_preferences!(user)
    return if !user.permissions? 'ticket.agent'

    user.fill_notification_config_preferences

    user.save!
  end

=begin

try to find correct name

  [firstname, lastname] = User.name_guess('Some Name', 'some.name@example.com')

=end

  def self.name_guess(string, email = nil)
    return if string.blank? && email.blank?

    string.strip!
    firstname = ''
    lastname = ''

    # "Lastname, Firstname"
    if string.match?(',')
      name = string.split(', ', 2)
      if name.count == 2
        if name[0].present?
          lastname = name[0].strip
        end
        if name[1].present?
          firstname = name[1].strip
        end
        return [firstname, lastname] if firstname.present? || lastname.present?
      end
    end

    # "Firstname Lastname"
    if string =~ %r{^(((Dr\.|Prof\.)[[:space:]]|).+?)[[:space:]](.+?)$}i
      if $1.present?
        firstname = $1.strip
      end
      if $4.present?
        lastname = $4.strip
      end
      return [firstname, lastname] if firstname.present? || lastname.present?
    end

    # -no name- "firstname.lastname@example.com"
    if string.blank? && email.present?
      scan = email.scan(%r{^(.+?)\.(.+?)@.+?$})
      if scan[0].present?
        if scan[0][0].present?
          firstname = scan[0][0].strip
        end
        if scan[0][1].present?
          lastname = scan[0][1].strip
        end
        return [firstname, lastname] if firstname.present? || lastname.present?
      end
    end

    nil
  end

  def no_name?
    firstname.blank? && lastname.blank?
  end

  # get locale identifier of user or system if user's own is not set
  def locale
    preferences.fetch(:locale) { Locale.default }
  end

  attr_accessor :skip_ensure_uniq_email

  def shared_organizations?
    all_organizations.exists? shared: true
  end

  def all_organizations
    Organization.where(id: all_organization_ids)
  end

  def all_organization_ids
    ([organization_id] + organization_ids).uniq
  end

  def organization_id?(organization_id)
    all_organization_ids.include?(organization_id)
  end

  def create_organization_add_history(org)
    organization_history_log(org, 'added')
  end

  def create_organization_remove_history(org)
    organization_history_log(org, 'removed')
  end

  def fill_notification_config_preferences
    preferences[:notification_config] ||= {}
    preferences[:notification_config][:matrix] = Setting.get('ticket_agent_default_notifications')
  end

  def mail_delivery_failed_blocked_days
    return 0 if !preferences[:mail_delivery_failed]
    return 0 if preferences[:mail_delivery_failed_data].blank?

    # Blocked for 60 full days; see #4459.
    remaining_days = (preferences[:mail_delivery_failed_data].to_date - Time.zone.now.to_date).to_i + 61
    return remaining_days if remaining_days.positive?

    reset_mail_delivery_failed

    0
  end

  def reset_mail_delivery_failed
    preferences[:mail_delivery_failed]      = false
    preferences[:mail_delivery_failed_data] = nil
    save!
  end

  private

  def organization_history_log(org, type)
    return if id.blank?

    attributes = {
      history_attribute: 'organization_ids',
      id_to:             org.id,
      value_to:          org.name
    }

    history_log(type, id, attributes)
  end

  def check_name
    self.firstname = sanitize_name(firstname)
    self.lastname  = sanitize_name(lastname)

    return if firstname.present? && lastname.present?

    if (firstname.blank? && lastname.present?) || (firstname.present? && lastname.blank?)
      used_name = firstname.presence || lastname
      (local_firstname, local_lastname) = User.name_guess(used_name, email)
    elsif firstname.blank? && lastname.blank? && email.present?
      (local_firstname, local_lastname) = User.name_guess('', email)
    end

    check_name_apply(:firstname, local_firstname)
    check_name_apply(:lastname, local_lastname)
  end

  def sanitize_name(value)
    result = value&.strip

    return result if result.blank?

    result.split(%r{\s}).map { |v| strip_uri(v) }.join("\s")
  end

  def strip_uri(value)
    uri = URI.parse(value)

    return value if !uri || uri.scheme.blank? || uri.hostname.blank?

    # Strip the scheme from the URI.
    uri.hostname + uri.path
  rescue
    value
  end

  def check_name_apply(identifier, input)
    self[identifier] = input if input.present?

    self[identifier].capitalize! if self[identifier]&.match? %r{^([[:upper:]]+|[[:lower:]]+)$}
  end

  def check_email
    return if Setting.get('import_mode')
    return if email.blank?

    # https://bugs.chromium.org/p/chromium/issues/detail?id=410937
    self.email = EmailHelper::Idn.to_unicode(email).downcase.strip
  end

  def ensure_email
    return if Setting.get('import_mode')
    return if email.blank?
    return if id == 1

    email_address_validation = EmailAddressValidation.new(email)

    return if email_address_validation.valid?

    errors.add :base, __("Invalid email '%{email}'"), email: email
  end

  def check_login

    # use email as login if not given
    if login.blank?
      self.login = email
    end

    # if email has changed, login is old email, change also login
    if email_changed? && email_was == login
      self.login = email
    end

    # generate auto login
    if login.blank?
      self.login = "auto-#{SecureRandom.uuid}"
    end

    # check if login already exists
    base_login = login.downcase.strip

    alternatives = [nil] + Array(1..20) + [ SecureRandom.uuid ]
    alternatives.each do |suffix|
      self.login = "#{base_login}#{suffix}"
      exists = User.find_by(login: login)
      return true if !exists || exists.id == id
    end

    raise Exceptions::UnprocessableEntity, "Invalid user login generation for login #{login}!"
  end

  def check_mail_delivery_failed
    return if email_change.blank?

    preferences.delete(:mail_delivery_failed)
  end

  def ensure_roles
    return if role_ids.present?

    self.role_ids = Role.signup_role_ids
  end

  def ensure_identifier
    return if login.present? && !login.start_with?('auto-')
    return if [email, firstname, lastname, phone, mobile].any?(&:present?)

    errors.add :base, __('At least one identifier (firstname, lastname, phone, mobile or email) for user is required.')
  end

  def ensure_uniq_email
    return if Setting.get('user_email_multiple_use')
    return if Setting.get('import_mode')
    return if email.blank?
    return if !email_changed?
    return if !User.exists?(email: email.downcase.strip)

    errors.add :base, __("Email address '%{email}' is already used for another user."), email: email.downcase.strip
  end

  def ensure_organizations
    return if organization_ids.blank?
    return if organization_id.present?

    errors.add :base, __('Secondary organizations are only allowed when the primary organization is given.')
  end

  def ensure_organizations_limit
    return if organization_ids.size <= 250

    errors.add :base, __('More than 250 secondary organizations are not allowed.')
  end

  def validate_roles(role)
    return true if !role_ids # we need role_ids for checking in role_ids below, in this method
    return true if role.preferences[:not].blank?

    role.preferences[:not].each do |local_role_name|
      local_role = Role.lookup(name: local_role_name)
      next if !local_role
      next if role_ids.exclude?(local_role.id)

      raise "Role #{role.name} conflicts with #{local_role.name}"
    end
    true
  end

  def validate_preferences
    return true if !changes
    return true if !changes['preferences']
    return true if preferences.blank?
    return true if !preferences[:notification_sound]
    return true if !preferences[:notification_sound][:enabled]

    case preferences[:notification_sound][:enabled]
    when 'true'
      preferences[:notification_sound][:enabled] = true
    when 'false'
      preferences[:notification_sound][:enabled] = false
    end
    class_name = preferences[:notification_sound][:enabled].class.to_s
    raise Exceptions::UnprocessableEntity, "preferences.notification_sound.enabled needs to be an boolean, but it was a #{class_name}" if class_name != 'TrueClass' && class_name != 'FalseClass'

    true
  end

  def ensure_notification_preferences
    fill_notification_config_preferences

    self.reset_notification_config_before_save = false
  end

=begin

checks if the current user is the last one with admin permissions.

Raises

raise 'At least one user need to have admin permissions'

=end

  def last_admin_check_by_attribute
    return true if !will_save_change_to_attribute?('active')
    return true if active != false
    return true if !permissions?(['admin', 'admin.user'])
    raise Exceptions::UnprocessableEntity, __('At least one user needs to have admin permissions.') if last_admin_check_admin_count < 1

    true
  end

  def last_admin_check_by_role(role)
    return true if Setting.get('import_mode')
    return true if !role.with_permission?(['admin', 'admin.user'])
    raise Exceptions::UnprocessableEntity, __('At least one user needs to have admin permissions.') if last_admin_check_admin_count < 1

    true
  end

  def last_admin_check_admin_count
    admin_role_ids = Role.joins(:permissions).where(permissions: { name: ['admin', 'admin.user'], active: true }, roles: { active: true }).pluck(:id)
    User.joins(:roles).where(roles: { id: admin_role_ids }, users: { active: true }).distinct.count - 1
  end

  def validate_agent_limit_by_attributes
    return true if Setting.get('system_agent_limit').blank?
    return true if !will_save_change_to_attribute?('active')
    return true if active != true
    return true if !permissions?('ticket.agent')

    ticket_agent_role_ids = Role.joins(:permissions).where(permissions: { name: 'ticket.agent', active: true }, roles: { active: true }).pluck(:id)
    count                 = User.joins(:roles).where(roles: { id: ticket_agent_role_ids }, users: { active: true }).distinct.count + 1
    raise Exceptions::UnprocessableEntity, __('Agent limit exceeded, please check your account settings.') if count > Setting.get('system_agent_limit').to_i

    true
  end

  def validate_agent_limit_by_role(role)
    return true if Setting.get('system_agent_limit').blank?
    return true if active != true
    return true if role.active != true
    return true if !role.with_permission?('ticket.agent')

    ticket_agent_role_ids = Role.joins(:permissions).where(permissions: { name: 'ticket.agent', active: true }, roles: { active: true }).pluck(:id)
    count                 = User.joins(:roles).where(roles: { id: ticket_agent_role_ids }, users: { active: true }).distinct.count

    # if new added role is a ticket.agent role
    if ticket_agent_role_ids.include?(role.id)

      # if user already has a ticket.agent role
      hint = false
      role_ids.each do |locale_role_id|
        next if ticket_agent_role_ids.exclude?(locale_role_id)

        hint = true
        break
      end

      # user has not already a ticket.agent role
      if hint == false
        count += 1
      end
    end
    raise Exceptions::UnprocessableEntity, __('Agent limit exceeded, please check your account settings.') if count > Setting.get('system_agent_limit').to_i

    true
  end

  def domain_based_assignment
    return true if !email
    return true if organization_id

    begin
      domain = Mail::Address.new(email).domain
      return true if !domain

      organization = Organization.find_by(domain: domain.downcase, domain_assignment: true)
      return true if !organization

      self.organization_id = organization.id
    rescue
      return true
    end
    true
  end

  # sets locale of the user
  def set_locale

    # set the user's locale to the one of the "executing" user
    return true if !UserInfo.current_user_id

    user = UserInfo.current_user
    return true if !user
    return true if !user.preferences[:locale]

    preferences[:locale] = user.preferences[:locale]
    true
  end

  def destroy_longer_required_objects
    ::Avatar.remove(self.class.to_s, id)
    ::UserDevice.remove(id)
    ::StatsStore.where(stats_storable: self).destroy_all
  end

  def destroy_move_dependency_ownership
    result = Models.references(self.class.to_s, id)

    user_columns = %w[created_by_id updated_by_id out_of_office_replacement_id origin_by_id owner_id archived_by_id published_by_id internal_by_id]
    result.each do |class_name, references|
      next if class_name.blank?
      next if references.blank?

      ref_class          = class_name.constantize
      ref_update_columns = []
      references.each do |column, reference_found|
        next if !reference_found

        if user_columns.include?(column)
          ref_update_columns << column
        elsif ref_class.exists?(column => id)
          raise "Failed deleting references! Check logic for #{class_name}->#{column}."
        end
      end

      next if ref_update_columns.blank?

      where_sql = ref_update_columns.map { |column| "#{column} = #{id}" }.join(' OR ')
      ref_class.where(where_sql).find_in_batches(batch_size: 1000) do |batch_list|
        batch_list.each do |record|
          ref_update_columns.each do |column|
            next if record[column] != id

            record[column] = 1
          end
          record.save!(validate: false)
        rescue => e
          Rails.logger.error e
        end
      end
    end

    true
  end

  def ensure_password
    return if !password_changed?

    self.password = ensured_password
  end

  def ensured_password
    # ensure unset password for blank values of new users
    return nil if new_record? && password.blank?

    # don't permit empty password update for existing users
    return password_was if password.blank?

    # don't re-hash passwords
    return password if PasswordHash.crypted?(password)

    if !PasswordPolicy::MaxLength.valid? password
      errors.add :password, __('is too long')
      return nil
    end

    # hash the plaintext password
    PasswordHash.crypt(password)
  end

  # reset login_failed if password is changed
  def reset_login_failed_after_password_change
    return true if !will_save_change_to_attribute?('password')

    self.login_failed = 0
    true
  end

  # When adding/removing a phone/mobile number from the User table,
  # update caller ID table
  # to adopt/orphan matching Cti::Logs accordingly
  # (see https://github.com/zammad/zammad/issues/2057)
  def update_caller_id
    # skip if "phone/mobile" does not change, or changes like [nil, ""]
    return if persisted? && previous_changes.slice(:phone, :mobile).values.flatten.none?(&:present?)
    return if destroyed? && phone.blank? && mobile.blank?

    Cti::CallerId.build(self)
  end
end
