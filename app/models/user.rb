# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

require 'digest/md5'

# @model User
#
# @property id(required)    [Integer] The identifier for the User.
# @property login(required) [String]  The login of the User used for authentication.
# @property firstname       [String]  The firstname of the User.
# @property lastname        [String]  The lastname of the User.
# @property email           [String]  The email of the User.
# @property image           [String]  The Image used as the User avatar (TODO: Image model?).
# @property web             [String]  The website/URL of the User.
# @property password        [String]  The password of the User.
# @property phone           [String]  The phone number of the User.
# @property fax             [String]  The fax number of the User.
# @property mobile          [String]  The mobile number of the User.
# @property department      [String]  The department the User is working at.
# @property street          [String]  The street the User lives in.
# @property zip             [Integer] The zip postal code of the User city.
# @property city            [String]  The city the User lives in.
# @property country         [String]  The country the User lives in.
# @property verified        [Boolean] The flag that shows the verified state of the User.
# @property active          [Boolean] The flag that shows the active state of the User.
# @property note            [String]  The note or comment stored to the User.
class User < ApplicationModel
  include HasActivityStreamLog
  include ChecksClientNotification
  include HasHistory
  include HasSearchIndexBackend
  include HasGroups
  include HasRoles
  include User::ChecksAccess

  load 'user/assets.rb'
  include User::Assets
  extend User::Search
  load 'user/search_index.rb'
  include User::SearchIndex

  before_validation :check_name, :check_email, :check_login, :ensure_uniq_email, :ensure_password, :ensure_roles, :ensure_identifier
  before_create   :check_preferences_default, :validate_roles, :validate_ooo, :domain_based_assignment, :set_locale
  before_update   :check_preferences_default, :validate_roles, :validate_ooo, :reset_login_failed
  after_create    :avatar_for_email_check
  after_update    :avatar_for_email_check
  after_destroy   :avatar_destroy, :user_device_destroy

  has_and_belongs_to_many :roles,           after_add: [:cache_update, :check_notifications], after_remove: :cache_update, before_add: :validate_agent_limit, before_remove: :last_admin_check, class_name: 'Role'
  has_and_belongs_to_many :organizations,   after_add: :cache_update, after_remove: :cache_update, class_name: 'Organization'
  #has_many                :permissions,     class_name: 'Permission', through: :roles, class_name: 'Role'
  has_many                :tokens,          after_add: :cache_update, after_remove: :cache_update
  has_many                :authorizations,  after_add: :cache_update, after_remove: :cache_update
  belongs_to              :organization,    class_name: 'Organization'

  store                   :preferences

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
                                  :login_failed,
                                  :preferences

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
    if firstname && !firstname.empty?
      name = name + firstname
    end
    if lastname && !lastname.empty?
      if name != ''
        name += ' '
      end
      name += lastname
    end
    if name == '' && email
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
    activity_stream = ActivityStream.list(self, limit)
    return activity_stream if !fulldata

    # get related objects
    assets = ApplicationModel.assets_of_object_list(activity_stream)

    {
      activity_stream: activity_stream,
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
    user.save
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

authenticate user agains sso

  result = User.sso(sso_params)

returns

  result = user_model # user model if authentication was successfully

=end

  def self.sso(params)

    # try to login against configure auth backends
    user_auth = Sso.check(params)
    return if !user_auth

    user_auth
  end

=begin

create user from from omni auth hash

  result = User.create_from_hash!(hash)

returns

  result = user_model # user model if create was successfully

=end

  def self.create_from_hash!(hash)

    role_ids = Role.signup_role_ids
    url = ''
    if hash['info']['urls']
      hash['info']['urls'].each { |_name, local_url|
        next if !local_url
        next if local_url.empty?
        url = local_url
      }
    end
    create(
      login: hash['info']['nickname'] || hash['uid'],
      firstname: hash['info']['name'],
      email: hash['info']['email'],
      image_source: hash['info']['image'],
      web: url,
      address: hash['info']['location'],
      note: hash['info']['description'],
      source: hash['provider'],
      role_ids: role_ids,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end

=begin

get all permissions of user

  user = User.find(123)
  user.permissions

returns

  {
    'permission.key' => true,
    # ...
  }

=end

  def permissions
    list = {}
    Object.const_get('Permission').select('permissions.name, permissions.preferences').joins(:roles).where('roles.id IN (?) AND permissions.active = ?', role_ids, true).pluck(:name, :preferences).each { |permission|
      next if permission[1]['selectable'] == false
      list[permission[0]] = true
    }
    list
  end

=begin

true or false for permission

  user = User.find(123)
  user.permissions?('permission.key') # access to certain permission.key
  user.permissions?(['permission.key1', 'permission.key2']) # access to permission.key1 or permission.key2

  user.permissions?('permission') # access to all sub keys

  user.permissions?('permission.*') # access if one sub key access exists

returns

  true|false

=end

  def permissions?(key)
    keys = key
    names = []
    if key.class == String
      keys = [key]
    end
    keys.each { |local_key|
      cache_key = "User::permissions?:local_key:::#{id}"
      if Rails.env.production?
        cache = Cache.get(cache_key)
        return cache if cache
      end
      list = []
      if local_key =~ /\.\*$/
        local_key.sub!('.*', '.%')
        permissions = Object.const_get('Permission').with_parents(local_key)
        list = Object.const_get('Permission').select('preferences').joins(:roles).where('roles.id IN (?) AND roles.active = ? AND (permissions.name IN (?) OR permissions.name LIKE ?) AND permissions.active = ?', role_ids, true, permissions, local_key, true).pluck(:preferences)
      else
        permission = Object.const_get('Permission').lookup(name: local_key)
        break if permission && permission.active == false
        permissions = Object.const_get('Permission').with_parents(local_key)
        list = Object.const_get('Permission').select('preferences').joins(:roles).where('roles.id IN (?) AND roles.active = ? AND permissions.name IN (?) AND permissions.active = ?', role_ids, true, permissions, true).pluck(:preferences)
      end
      list.each { |preferences|
        next if preferences[:selectable] == false
        Cache.write(key, true, expires_in: 10.seconds)
        return true
      }
    }
    Cache.write(key, false, expires_in: 10.seconds)
    false
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
    permissions.each { |permission_name, _value|
      where += ' OR ' if where != ''
      where += 'permissions.name = ? OR permissions.name LIKE ?'
      where_bind.push permission_name
      where_bind.push "#{permission_name}.%"
    }
    return [] if where == ''
    Object.const_get('Permission').where("permissions.active = ? AND (#{where})", *where_bind).pluck(:id)
  end

=begin

get all users with permission

  users = User.with_permissions('admin.session')

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
    keys.each { |key|
      role_ids = []
      Object.const_get('Permission').with_parents(key).each { |local_key|
        permission = Object.const_get('Permission').lookup(name: local_key)
        next if !permission
        permission_ids.push permission.id
      }
      next if permission_ids.empty?
      Role.joins(:roles_permissions).joins(:permissions).where('permissions_roles.permission_id IN (?) AND roles.active = ? AND permissions.active = ?', permission_ids, true, true).uniq().pluck(:id).each { |role_id|
        role_ids.push role_id
      }
      total_role_ids.push role_ids
    }
    return [] if total_role_ids.empty?
    condition = ''
    total_role_ids.each { |_role_ids|
      if condition != ''
        condition += ' OR '
      end
      condition += 'roles_users.role_id IN (?)'
    }
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
    user = User.find_by(login: username.downcase, active: true)

    # try second lookup with email
    user ||= User.find_by(email: username.downcase, active: true)

    # check if email address exists
    return if !user
    return if !user.email

    # generate token
    token = Token.create(action: 'PasswordReset', user_id: user.id)

    {
      token: token,
      user: user,
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
    user.update_attributes(password: password)

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
    self.last_login = Time.zone.now

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
      user: user,
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
    local_user.update_attributes(verified: true)

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

    # find email addresses and move them to primary user
    duplicate_user = User.find(user_id_of_duplicate_user)

    # merge missing attibutes
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
      return User.where(active: true).joins(:users_roles).where('roles_users.role_id IN (?)', roles_ids).order('users.updated_at DESC')
    end
    User.where(active: true)
        .joins(:users_roles)
        .joins(:users_groups)
        .where('roles_users.role_id IN (?) AND users_groups.group_ids IN (?)', roles_ids, group_ids).order('users.updated_at DESC')
  end

=begin

update/sync default preferences of users in a dedecated permissions

  result = User.update_default_preferences_by_permission('ticket.agent', force)

returns

  result = true # false

=end

  def self.update_default_preferences_by_permission(permission_name, force = false)
    permission = Object.const_get('Permission').lookup(name: permission_name)
    return if !permission
    default = Rails.configuration.preferences_default_by_permission
    return false if !default
    default.deep_stringify_keys!
    User.with_permissions(permission.name).each { |user|
      next if !default[permission.name]
      has_changed = false
      default[permission.name].each { |key, value|
        next if !force && user.preferences[key]
        has_changed = true
        user.preferences[key] = value
      }
      if has_changed
        user.save!
      end
    }
    true
  end

=begin

update/sync default preferences of users in a dedecated role

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
    role.permissions.each { |permission|
      User.update_default_preferences_by_permission(permission.name, force)
    }
    true
  end

  def check_notifications(o, shouldSave = true)
    default = Rails.configuration.preferences_default_by_permission
    return if !default
    default.deep_stringify_keys!
    has_changed = false
    o.permissions.each { |permission|
      next if !default[permission.name]
      default[permission.name].each { |key, value|
        next if preferences[key]
        preferences[key] = value
        has_changed = true
      }
    }

    return true if !has_changed

    if id && shouldSave
      save!
      return true
    end

    @preferences_default = preferences
    true
  end

  def check_preferences_default
    if @preferences_default.blank?
      if id
        roles.each { |role|
          check_notifications(role, false)
        }
      end
    end
    return if @preferences_default.blank?
    preferences_tmp = @preferences_default.merge(preferences)
    self.preferences = preferences_tmp
    @preferences_default = nil
    true
  end

  private

  def cache_delete
    super

    # delete asset caches
    key = "User::authorizations::#{id}"
    Cache.delete(key)

    # delete permission cache
    key = "User::permissions?:local_key:::#{id}"
    Cache.delete(key)
  end

  def check_name
    return true if !firstname.empty? && !lastname.empty?

    if !firstname.empty? && lastname.empty?

      # "Lastname, Firstname"
      scan = firstname.scan(/, /)
      if scan[0]
        name = firstname.split(', ', 2)
        if !name[0].nil?
          self.lastname  = name[0]
        end
        if !name[1].nil?
          self.firstname = name[1]
        end
        return true
      end

      # "Firstname Lastname"
      name = firstname.split(' ', 2)
      if !name[0].nil?
        self.firstname = name[0]
      end
      if !name[1].nil?
        self.lastname = name[1]
      end
      return true

    # -no name- "firstname.lastname@example.com"
    elsif firstname.empty? && lastname.empty? && !email.empty?
      scan = email.scan(/^(.+?)\.(.+?)\@.+?$/)
      if scan[0]
        if !scan[0][0].nil?
          self.firstname = scan[0][0].capitalize
        end
        if !scan[0][1].nil?
          self.lastname  = scan[0][1].capitalize
        end
      end
    end
    true
  end

  def check_email
    return true if Setting.get('import_mode')
    return true if email.blank?
    self.email = email.downcase.strip
    return true if id == 1
    raise Exceptions::UnprocessableEntity, 'Invalid email' if email !~ /@/
    raise Exceptions::UnprocessableEntity, 'Invalid email' if email =~ /\s/
    true
  end

  def check_login

    # use email as login if not given
    if login.blank?
      self.login = email
    end

    # if email has changed, login is old email, change also login
    if changes && changes['email']
      if changes['email'][0] == login
        self.login = email
      end
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
    return true if !User.find_by(email: email.downcase.strip)
    raise Exceptions::UnprocessableEntity, 'Email address is already used for other user.'
  end

  def validate_roles
    return true if !role_ids
    role_ids.each { |role_id|
      role = Role.lookup(id: role_id)
      raise "Unable to find role for id #{role_id}" if !role
      next if !role.preferences[:not]
      role.preferences[:not].each { |local_role_name|
        local_role = Role.lookup(name: local_role_name)
        next if !local_role
        raise "Role #{role.name} conflicts with #{local_role.name}" if role_ids.include?(local_role.id)
      }
    }
    true
  end

  def validate_ooo
    return true if out_of_office != true
    raise Exceptions::UnprocessableEntity, 'out of office start is required' if out_of_office_start_at.blank?
    raise Exceptions::UnprocessableEntity, 'out of office end is required' if out_of_office_end_at.blank?
    raise Exceptions::UnprocessableEntity, 'out of office end is before start' if out_of_office_start_at > out_of_office_end_at
    raise Exceptions::UnprocessableEntity, 'out of office replacement user is required' if out_of_office_replacement_id.blank?
    raise Exceptions::UnprocessableEntity, 'out of office no such replacement user' if !User.find_by(id: out_of_office_replacement_id)
    true
  end
=begin

checks if the current user is the last one
with admin permissions.

Raises

raise 'Minimum one user need to have admin permissions'

=end

  def last_admin_check(role)
    return true if Setting.get('import_mode')

    ticket_admin_role_ids = Role.joins(:permissions).where(permissions: { name: ['admin', 'admin.user'] }).pluck(:id)
    count                 = User.joins(:roles).where(roles: { id: ticket_admin_role_ids }, users: { active: true }).count
    if ticket_admin_role_ids.include?(role.id)
      count -= 1
    end

    raise Exceptions::UnprocessableEntity, 'Minimum one user needs to have admin permissions.' if count < 1
    true
  end

  def validate_agent_limit(role)
    return true if !Setting.get('system_agent_limit')

    ticket_agent_role_ids = Role.joins(:permissions).where(permissions: { name: 'ticket.agent' }).pluck(:id)
    count                 = User.joins(:roles).where(roles: { id: ticket_agent_role_ids }, users: { active: true }).count
    if ticket_agent_role_ids.include?(role.id)
      count += 1
    end

    raise Exceptions::UnprocessableEntity, 'Agent limit exceeded, please check your account settings.' if count > Setting.get('system_agent_limit')
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

  def avatar_for_email_check
    return true if email.blank?
    return true if email !~ /@/
    return true if !changes['email'] && updated_at > Time.zone.now - 10.days

    # save/update avatar
    avatar = Avatar.auto_detection(
      object: 'User',
      o_id: id,
      url: email,
      source: 'app',
      updated_by_id: updated_by_id,
      created_by_id: updated_by_id,
    )

    # update user link
    return true if !avatar

    update_column(:image, avatar.store_hash)
    cache_delete
    true
  end

  def avatar_destroy
    Avatar.remove('User', id)
  end

  def user_device_destroy
    UserDevice.remove(id)
  end

  def ensure_password
    return true if password_empty?
    return true if PasswordHash.crypted?(password)
    self.password = PasswordHash.crypt(password)
    true
  end

  def password_empty?
    # set old password again if not given
    return if password.present?

    # skip if it's not desired to set a password (yet)
    return true if !password

    # get current record
    return if !id

    self.password = password_was
    true
  end

  # reset login_failed if password is changed
  def reset_login_failed
    return true if !changes
    return true if !changes['password']
    self.login_failed = 0
    true
  end
end
