# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'karma/user'

class User < ApplicationModel
  include CanBeAuthorized
  include CanBeImported
  include HasActivityStreamLog
  include ChecksClientNotification
  include HasHistory
  include HasSearchIndexBackend
  include CanCsvImport
  include ChecksHtmlSanitized
  include HasGroups
  include HasRoles
  include HasObjectManagerAttributesValidation
  include HasTicketCreateScreenImpact
  include HasTaskbars
  include User::HasTicketCreateScreenImpact
  include User::Assets
  include User::Avatar
  include User::Search
  include User::SearchIndex
  include User::TouchesOrganization
  include User::PerformsGeoLookup
  include User::UpdatesTicketOrganization

  include HasTransactionDispatcher

  has_and_belongs_to_many :organizations,          after_add: :cache_update, after_remove: :cache_update, class_name: 'Organization'
  has_and_belongs_to_many :overviews,              dependent: :nullify
  has_many                :tokens,                 after_add: :cache_update, after_remove: :cache_update, dependent: :destroy
  has_many                :authorizations,         after_add: :cache_update, after_remove: :cache_update, dependent: :destroy
  has_many                :online_notifications,   dependent: :destroy
  has_many                :taskbars,               dependent: :destroy
  has_many                :user_devices,           dependent: :destroy
  has_one                 :chat_agent_created_by,  class_name: 'Chat::Agent', foreign_key: :created_by_id, dependent: :destroy, inverse_of: :created_by
  has_one                 :chat_agent_updated_by,  class_name: 'Chat::Agent', foreign_key: :updated_by_id, dependent: :destroy, inverse_of: :updated_by
  has_many                :chat_sessions,          class_name: 'Chat::Session', dependent: :destroy
  has_many                :karma_user,             class_name: 'Karma::User', dependent: :destroy
  has_many                :mentions,               dependent: :destroy
  has_many                :karma_activity_logs,    class_name: 'Karma::ActivityLog', dependent: :destroy
  has_many                :cti_caller_ids,         class_name: 'Cti::CallerId', dependent: :destroy
  has_many                :customer_tickets,       class_name: 'Ticket', foreign_key: :customer_id, dependent: :destroy, inverse_of: :customer
  has_many                :owner_tickets,          class_name: 'Ticket', foreign_key: :owner_id, inverse_of: :owner
  has_many                :created_recent_views,   class_name: 'RecentView', foreign_key: :created_by_id, dependent: :destroy, inverse_of: :created_by
  has_many                :permissions,            -> { where(roles: { active: true }, active: true) }, through: :roles
  has_many                :data_privacy_tasks,     as: :deletable
  belongs_to              :organization,           inverse_of: :members, optional: true

  before_validation :check_name, :check_email, :check_login, :ensure_uniq_email, :ensure_password, :ensure_roles, :ensure_identifier
  before_validation :check_mail_delivery_failed, on: :update
  before_create     :check_preferences_default, :validate_preferences, :validate_ooo, :domain_based_assignment, :set_locale
  before_update     :check_preferences_default, :validate_preferences, :validate_ooo, :reset_login_failed, :validate_agent_limit_by_attributes, :last_admin_check_by_attribute
  before_destroy    :destroy_longer_required_objects, :destroy_move_dependency_ownership
  after_commit      :update_caller_id

  store :preferences

  association_attributes_ignored :online_notifications, :templates, :taskbars, :user_devices, :chat_sessions, :karma_activity_logs, :cti_caller_ids, :text_modules, :customer_tickets, :owner_tickets, :created_recent_views, :chat_agents, :data_privacy_tasks, :overviews, :mentions

  activity_stream_permission 'admin.user'

  activity_stream_attributes_ignored :last_login,
                                     :login_failed,
                                     :image,
                                     :image_source,
                                     :preferences

  association_attributes_ignored :permissions

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
                         :organizations,
                         :groups,
                         :user_groups

  sanitized_html :note

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

  def fullname
    name = ''
    if firstname.present?
      name = firstname
    end
    if lastname.present?
      if name != ''
        name += ' '
      end
      name += lastname
    end
    if name.blank? && email.present?
      name = email
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

check if user is in role

  user = User.find(123)
  result = user.out_of_office?

returns

  result = true|false

=end

  def out_of_office?
    return false if out_of_office != true
    return false if out_of_office_start_at.blank?
    return false if out_of_office_end_at.blank?

    Time.zone.today.between?(out_of_office_start_at, out_of_office_end_at)
  end

=begin

check if user is in role

  user = User.find(123)
  result = user.out_of_office_agent

returns

  result = user_model

=end

  def out_of_office_agent
    return if !out_of_office?
    return if out_of_office_replacement_id.blank?

    User.find_by(id: out_of_office_replacement_id)
  end

=begin

gets users where user is replacement

  user = User.find(123)
  result = user.out_of_office_agent_of

returns

  result = [user_model1, user_model2]

=end

  def out_of_office_agent_of
    User.where(active: true, out_of_office: true, out_of_office_replacement_id: id).where('out_of_office_start_at <= ? AND out_of_office_end_at >= ?', Time.zone.today, Time.zone.today)
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

authenticate user

  result = User.authenticate(username, password)

returns

  result = user_model # user model if authentication was successfully

=end

  def self.authenticate(username, password)

    # do not authenticate with nothing
    return if username.blank? || password.blank?

    user = User.identify(username)
    return if !user

    return if !Auth.can_login?(user)

    return user if Auth.valid?(user, password)

    sleep 1
    user.login_failed += 1
    user.save!
    nil
  end

=begin

checks if a user has reached the maximum of failed login tries

  user = User.find(123)
  result = user.max_login_failed?

returns

  result = true | false

=end

  def max_login_failed?
    max_login_failed = Setting.get('password_max_login_failed').to_i || 10
    login_failed > max_login_failed
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

=begin

returns all accessable permission ids of user

  user = User.find(123)
  user.permissions_with_child_ids

returns

  [permission1_id, permission2_id, permission3_id]

=end

  def permissions_with_child_ids
    where = ''
    where_bind = [true]
    permissions.pluck(:name).each do |permission_name|
      where += ' OR ' if where != ''
      where += 'permissions.name = ? OR permissions.name LIKE ?'
      where_bind.push permission_name
      where_bind.push "#{permission_name}.%"
    end
    return [] if where == ''

    ::Permission.where("permissions.active = ? AND (#{where})", *where_bind).pluck(:id)
  end

=begin

get all users with permission

  users = User.with_permissions('ticket.agent')

get all users with permission "admin.session" or "ticket.agent"

  users = User.with_permissions(['admin.session', 'ticket.agent'])

returns

  [user1, user2, ...]

=end

  def self.with_permissions(keys)
    if keys.class != Array
      keys = [keys]
    end
    total_role_ids = []
    permission_ids = []
    keys.each do |key|
      role_ids = []
      ::Permission.with_parents(key).each do |local_key|
        permission = ::Permission.lookup(name: local_key)
        next if !permission

        permission_ids.push permission.id
      end
      next if permission_ids.blank?

      Role.joins(:roles_permissions).joins(:permissions).where('permissions_roles.permission_id IN (?) AND roles.active = ? AND permissions.active = ?', permission_ids, true, true).distinct().pluck(:id).each do |role_id|
        role_ids.push role_id
      end
      total_role_ids.push role_ids
    end
    return [] if total_role_ids.blank?

    condition = ''
    total_role_ids.each do |_role_ids|
      if condition != ''
        condition += ' OR '
      end
      condition += 'roles_users.role_id IN (?)'
    end
    User.joins(:users_roles).where("(#{condition}) AND users.active = ?", *total_role_ids, true).distinct.order(:id)
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

    # check if email address exists
    return if !user
    return if !user.email

    # generate token
    token = Token.create(action: 'PasswordReset', user_id: user.id)

    {
      token: token,
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
    Token.check(action: 'PasswordReset', name: token)
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
    Token.find_by(action: 'PasswordReset', name: token).destroy
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
    local_user = Token.check(action: 'Signup', name: token)
    return if !local_user

    # if requested user is different to current user
    return if user && local_user.id != user.id

    # set verified
    local_user.update!(verified: true)

    # delete token
    Token.find_by(action: 'Signup', name: token).destroy
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
      return User.where(active: true).joins(:users_roles).where('roles_users.role_id' => roles_ids).order('users.updated_at DESC')
    end

    User.where(active: true)
        .joins(:users_roles)
        .joins(:users_groups)
        .where('roles_users.role_id IN (?) AND users_groups.group_ids IN (?)', roles_ids, group_ids).order('users.updated_at DESC')
  end

=begin

update/sync default preferences of users with dedicated permissions

  result = User.update_default_preferences_by_permission('ticket.agent', force)

returns

  result = true # false

=end

  def self.update_default_preferences_by_permission(permission_name, force = false)
    permission = ::Permission.lookup(name: permission_name)
    return if !permission

    default = Rails.configuration.preferences_default_by_permission
    return false if !default

    default.deep_stringify_keys!
    User.with_permissions(permission.name).each do |user|
      next if !default[permission.name]

      has_changed = false
      default[permission.name].each do |key, value|
        next if !force && user.preferences[key]

        has_changed = true
        user.preferences[key] = value
      end
      if has_changed
        user.save!
      end
    end
    true
  end

=begin

update/sync default preferences of users in a dedicated role

  result = User.update_default_preferences_by_role('Agent', force)

returns

  result = true # false

=end

  def self.update_default_preferences_by_role(role_name, force = false)
    role = Role.lookup(name: role_name)
    return if !role

    default = Rails.configuration.preferences_default_by_permission
    return false if !default

    default.deep_stringify_keys!
    role.permissions.each do |permission|
      User.update_default_preferences_by_permission(permission.name, force)
    end
    true
  end

  def check_notifications(other, should_save = true)
    default = Rails.configuration.preferences_default_by_permission
    return if !default

    default.deep_stringify_keys!
    has_changed = false
    other.permissions.each do |permission|
      next if !default[permission.name]

      default[permission.name].each do |key, value|
        next if preferences[key]

        preferences[key] = value
        has_changed = true
      end
    end

    return true if !has_changed

    if id && should_save
      save!
      return true
    end

    @preferences_default = preferences
    true
  end

  def check_preferences_default
    if @preferences_default.blank? && id
      roles.each do |role|
        check_notifications(role, false)
      end
    end

    return if @preferences_default.blank?

    preferences_tmp = @preferences_default.merge(preferences)
    self.preferences = preferences_tmp
    @preferences_default = nil
    true
  end

  def cache_delete
    super

    # delete asset caches
    key = "User::authorizations::#{id}"
    Cache.delete(key)

    # delete permission cache
    key = "User::permissions?:local_key:::#{id}"
    Cache.delete(key)
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

  private

  def check_name
    if firstname.present?
      firstname.strip!
    end
    if lastname.present?
      lastname.strip!
    end

    return true if firstname.present? && lastname.present?

    if (firstname.blank? && lastname.present?) || (firstname.present? && lastname.blank?)
      used_name = firstname.presence || lastname
      (local_firstname, local_lastname) = User.name_guess(used_name, email)

    elsif firstname.blank? && lastname.blank? && email.present?
      (local_firstname, local_lastname) = User.name_guess('', email)
    end

    self.firstname = local_firstname if local_firstname.present?
    self.lastname = local_lastname if local_lastname.present?

    if firstname.present? && firstname.match(%r{^[A-z]+$}) && (firstname.downcase == firstname || firstname.upcase == firstname)
      firstname.capitalize!
    end
    if lastname.present? && lastname.match(%r{^[A-z]+$}) && (lastname.downcase == lastname || lastname.upcase == lastname)
      lastname.capitalize!
    end
    true
  end

  def check_email
    return true if Setting.get('import_mode')
    return true if email.blank?

    self.email = email.downcase.strip
    return true if id == 1

    email_address_validation = EmailAddressValidation.new(email)
    if !email_address_validation.valid_format?
      raise Exceptions::UnprocessableEntity, "Invalid email '#{email}'"
    end

    true
  end

  def check_login

    # use email as login if not given
    if login.blank?
      self.login = email
    end

    # if email has changed, login is old email, change also login
    if changes && changes['email'] && changes['email'][0] == login
      self.login = email
    end

    # generate auto login
    if login.blank?
      self.login = "auto-#{Time.zone.now.to_i}-#{rand(999_999)}"
    end

    # check if login already exists
    self.login = login.downcase.strip
    check      = true
    while check
      exists = User.find_by(login: login)
      if exists && exists.id != id
        self.login = "#{login}#{rand(999)}"
      else
        check = false
      end
    end
    true
  end

  def check_mail_delivery_failed
    return if email_change.blank?

    preferences.delete(:mail_delivery_failed)
  end

  def ensure_roles
    return true if role_ids.present?

    self.role_ids = Role.signup_role_ids
  end

  def ensure_identifier
    return true if email.present? || firstname.present? || lastname.present? || phone.present?
    return true if login.present? && !login.start_with?('auto-')

    raise Exceptions::UnprocessableEntity, 'Minimum one identifier (login, firstname, lastname, phone or email) for user is required.'
  end

  def ensure_uniq_email
    return true if Setting.get('user_email_multiple_use')
    return true if Setting.get('import_mode')
    return true if email.blank?
    return true if !changes
    return true if !changes['email']
    return true if !User.exists?(email: email.downcase.strip)

    raise Exceptions::UnprocessableEntity, "Email address '#{email.downcase.strip}' is already used for other user."
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

  def validate_ooo
    return true if out_of_office != true
    raise Exceptions::UnprocessableEntity, 'out of office start is required' if out_of_office_start_at.blank?
    raise Exceptions::UnprocessableEntity, 'out of office end is required' if out_of_office_end_at.blank?
    raise Exceptions::UnprocessableEntity, 'out of office end is before start' if out_of_office_start_at > out_of_office_end_at
    raise Exceptions::UnprocessableEntity, 'out of office replacement user is required' if out_of_office_replacement_id.blank?
    raise Exceptions::UnprocessableEntity, 'out of office no such replacement user' if !User.exists?(id: out_of_office_replacement_id)

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
    raise Exceptions::UnprocessableEntity, "preferences.notification_sound.enabled need to be an boolean, but it was a #{class_name}" if class_name != 'TrueClass' && class_name != 'FalseClass'

    true
  end

=begin

checks if the current user is the last one with admin permissions.

Raises

raise 'Minimum one user need to have admin permissions'

=end

  def last_admin_check_by_attribute
    return true if !will_save_change_to_attribute?('active')
    return true if active != false
    return true if !permissions?(['admin', 'admin.user'])
    raise Exceptions::UnprocessableEntity, 'Minimum one user needs to have admin permissions.' if last_admin_check_admin_count < 1

    true
  end

  def last_admin_check_by_role(role)
    return true if Setting.get('import_mode')
    return true if !role.with_permission?(['admin', 'admin.user'])
    raise Exceptions::UnprocessableEntity, 'Minimum one user needs to have admin permissions.' if last_admin_check_admin_count < 1

    true
  end

  def last_admin_check_admin_count
    admin_role_ids = Role.joins(:permissions).where(permissions: { name: ['admin', 'admin.user'], active: true }, roles: { active: true }).pluck(:id)
    User.joins(:roles).where(roles: { id: admin_role_ids }, users: { active: true }).distinct().count - 1
  end

  def validate_agent_limit_by_attributes
    return true if Setting.get('system_agent_limit').blank?
    return true if !will_save_change_to_attribute?('active')
    return true if active != true
    return true if !permissions?('ticket.agent')

    ticket_agent_role_ids = Role.joins(:permissions).where(permissions: { name: 'ticket.agent', active: true }, roles: { active: true }).pluck(:id)
    count                 = User.joins(:roles).where(roles: { id: ticket_agent_role_ids }, users: { active: true }).distinct().count + 1
    raise Exceptions::UnprocessableEntity, 'Agent limit exceeded, please check your account settings.' if count > Setting.get('system_agent_limit').to_i

    true
  end

  def validate_agent_limit_by_role(role)
    return true if Setting.get('system_agent_limit').blank?
    return true if active != true
    return true if role.active != true
    return true if !role.with_permission?('ticket.agent')

    ticket_agent_role_ids = Role.joins(:permissions).where(permissions: { name: 'ticket.agent', active: true }, roles: { active: true }).pluck(:id)
    count                 = User.joins(:roles).where(roles: { id: ticket_agent_role_ids }, users: { active: true }).distinct().count

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
    raise Exceptions::UnprocessableEntity, 'Agent limit exceeded, please check your account settings.' if count > Setting.get('system_agent_limit').to_i

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

    user = User.find_by(id: UserInfo.current_user_id)
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
          record.save!
        rescue => e
          Rails.logger.error e
        end
      end
    end

    true
  end

  def ensure_password
    self.password = ensured_password
    true
  end

  def ensured_password
    # ensure unset password for blank values of new users
    return nil if new_record? && password.blank?

    # don't permit empty password update for existing users
    return password_was if password.blank?

    # don't re-hash passwords
    return password if PasswordHash.crypted?(password)

    # hash the plaintext password
    PasswordHash.crypt(password)
  end

  # reset login_failed if password is changed
  def reset_login_failed
    return true if !will_save_change_to_attribute?('password')

    self.login_failed = 0
    true
  end

  # When adding/removing a phone number from the User table,
  # update caller ID table
  # to adopt/orphan matching Cti::Logs accordingly
  # (see https://github.com/zammad/zammad/issues/2057)
  def update_caller_id
    # skip if "phone" does not change, or changes like [nil, ""]
    return if persisted? && !previous_changes[:phone]&.any?(&:present?)
    return if destroyed? && phone.blank?

    Cti::CallerId.build(self)
  end
end
