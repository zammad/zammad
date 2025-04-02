# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class UsersController < ApplicationController
  include ChecksUserAttributesByCurrentUserPermission
  include CanPaginate

  prepend_before_action -> { authorize! }, only: %i[import_example import_start search history unlock]
  prepend_before_action :authentication_check, except: %i[create password_reset_send password_reset_verify image email_verify email_verify_send admin_password_auth_send admin_password_auth_verify]
  prepend_before_action :authentication_check_only, only: %i[create]

  # @path       [GET] /users
  #
  # @summary          Returns a list of User records.
  # @notes            The requester has to be in the role 'Admin' or 'Agent' to
  #                   get a list of all Users. If the requester is in the
  #                   role 'Customer' only just the own User record will be returned.
  #
  # @response_message 200 [Array<User>] List of matching User records.
  # @response_message 403               Forbidden / Invalid session.
  def index
    users = policy_scope(User).reorder(id: :asc).offset(pagination.offset).limit(pagination.limit)

    if response_expand?
      list = users.map(&:attributes_with_association_names)
      render json: list, status: :ok
      return
    end

    if response_full?
      assets = {}
      item_ids = []
      users.each do |item|
        item_ids.push item.id
        assets = item.assets(assets)
      end
      render json: {
        record_ids: item_ids,
        assets:     assets,
      }, status: :ok
      return
    end

    users_all = users.map do |user|
      User.lookup(id: user.id).attributes_with_association_ids
    end
    render json: users_all, status: :ok
  end

  # @path       [GET] /users/{id}
  #
  # @summary          Returns the User record with the requested identifier.
  # @notes            The requester has to be in the role 'Admin' or 'Agent' to
  #                   access all User records. If the requester is in the
  #                   role 'Customer' just the own User record is accessable.
  #
  # @parameter        id(required) [Integer] The identifier matching the requested User.
  # @parameter        full         [Bool]    If set a Asset structure with all connected Assets gets returned.
  #
  # @response_message 200 [User] User record matching the requested identifier.
  # @response_message 403        Forbidden / Invalid session.
  def show
    user = User.find(params[:id])
    authorize!(user)

    if response_expand?
      result = user.attributes_with_association_names
      result.delete('password')
      render json: result
      return
    end

    if response_full?
      result = {
        id:     user.id,
        assets: user.assets({}),
      }
      render json: result
      return
    end

    result = user.attributes_with_association_ids
    result.delete('password')
    render json: result
  end

  # @path      [POST] /users
  #
  # @summary processes requests as CRUD-like record creation, admin creation or user signup depending on circumstances
  # @see #create_internal #create_admin #create_signup
  def create
    if current_user
      create_internal
    elsif params[:signup]
      create_signup
    else
      create_admin
    end
  end

  # @path       [PUT] /users/{id}
  #
  # @summary          Updates the User record matching the identifier with the provided attribute values.
  # @notes            TODO.
  #
  # @parameter        id(required)        [Integer] The identifier matching the requested User record.
  # @parameter        User(required,body) [User]    The attribute value structure needed to update a User record.
  #
  # @response_message 200 [User] Updated User record.
  # @response_message 403        Forbidden / Invalid session.
  def update
    user = User.find(params[:id])
    authorize!(user)

    # permission check
    check_attributes_by_current_user_permission(params)
    user.with_lock do
      clean_params = User.association_name_to_id_convert(params)
      clean_params = User.param_cleanup(clean_params, true)
      clean_params[:screen] = 'edit'

      # presence and permissions were checked via `check_attributes_by_current_user_permission`
      privileged_attributes = params.slice(:role_ids, :roles, :group_ids, :groups, :organization_ids, :organizations)

      if privileged_attributes.present?
        user.associations_from_param(privileged_attributes)
      end

      user.update!(clean_params)
    end

    if response_expand?
      user = user.reload.attributes_with_association_names
      user.delete('password')
      render json: user, status: :ok
      return
    end

    if response_full?
      result = {
        id:     user.id,
        assets: user.assets({}),
      }
      render json: result, status: :ok
      return
    end

    user = user.reload.attributes_with_association_ids
    user.delete('password')
    render json: user, status: :ok
  end

  # @path    [DELETE] /users/{id}
  #
  # @summary          Deletes the User record matching the given identifier.
  # @notes            The requester has to be in the role 'Admin' to be able to delete a User record.
  #
  # @parameter        id(required) [User] The identifier matching the requested User record.
  #
  # @response_message 200 User successfully deleted.
  # @response_message 403 Forbidden / Invalid session.
  def destroy
    user = User.find(params[:id])
    authorize!(user)

    model_references_check(User, params)
    model_destroy_render(User, params)
  end

  # @path       [GET] /users/me
  #
  # @summary          Returns the User record of current user.
  # @notes            The requester needs to have a valid authentication.
  #
  # @parameter        full         [Bool]    If set a Asset structure with all connected Assets gets returned.
  #
  # @response_message 200 [User] User record matching the requested identifier.
  # @response_message 403        Forbidden / Invalid session.
  def me

    if response_expand?
      user = current_user.attributes_with_association_names
      user.delete('password')
      render json: user, status: :ok
      return
    end

    if response_full?
      full = User.full(current_user.id)
      render json: full
      return
    end

    user = current_user.attributes_with_association_ids
    user.delete('password')
    render json: user
  end

  # @path       [GET] /users/search
  #
  # @tag Search
  # @tag User
  #
  # @summary          Searches the User matching the given expression(s).
  # @notes            TODO: It's possible to use the SOLR search syntax.
  #                   The requester has to be in the role 'Admin' or 'Agent' to
  #                   be able to search for User records.
  #
  # @parameter        query              [String]                               The search query.
  # @parameter        limit              [Integer]                              The limit of search results.
  # @parameter        ids(multi)         [Array<Integer>]                       A list of User IDs which should be returned
  # @parameter        role_ids(multi)    [Array<Integer>]                       A list of Role identifiers to which the Users have to be allocated to.
  # @parameter        group_ids(multi)   [Hash<String=>Integer,Array<Integer>>] A list of Group identifiers to which the Users have to be allocated to.
  # @parameter        permissions(multi) [Array<String>]                        A list of Permission identifiers to which the Users have to be allocated to.
  # @parameter        full               [Boolean]                              Defines if the result should be
  #                                                                             true: { user_ids => [1,2,...], assets => {...} }
  #                                                                             or false: [{:id => user.id, :label => "firstname lastname <email>", :value => "firstname lastname <email>"},...].
  #
  # @response_message 200 [Array<User>] A list of User records matching the search term.
  # @response_message 403               Forbidden / Invalid session.
  def search
    model_search_render(User, params)
  end

  # @path       [GET] /users/history/{id}
  #
  # @tag History
  # @tag User
  #
  # @summary          Returns the History records of a User record matching the given identifier.
  # @notes            The requester has to be in the role 'Admin' or 'Agent' to
  #                   get the History records of a User record.
  #
  # @parameter        id(required) [Integer] The identifier matching the requested User record.
  #
  # @response_message 200 [History] The History records of the requested User record.
  # @response_message 403           Forbidden / Invalid session.
  def history
    # get user data
    user = User.find(params[:id])

    # get history of user
    render json: user.history_get(true)
  end

  # @path       [PUT] /users/unlock/{id}
  #
  # @summary          Unlocks the User record matching the identifier.
  # @notes            The requester have 'admin.user' permissions to be able to unlock a user.
  #
  # @parameter        id(required) [Integer] The identifier matching the requested User record.
  #
  # @response_message 200 Unlocked User record.
  # @response_message 403 Forbidden / Invalid session.
  def unlock
    user = User.find(params[:id])

    user.with_lock do
      user.update!(login_failed: 0)
    end
    render json: { message: 'ok' }, status: :ok
  end

=begin

Resource:
POST /api/v1/users/email_verify

Payload:
{
  "token": "SoMeToKeN",
}

Response:
{
  :message => 'ok'
}

Test:
curl http://localhost/api/v1/users/email_verify -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"token": "SoMeToKeN"}'

=end

  def email_verify
    raise Exceptions::UnprocessableEntity, __('No token!') if !params[:token]

    verify = Service::User::SignupVerify.new(token: params[:token], current_user: current_user)

    begin
      user = verify.execute
    rescue Service::CheckFeatureEnabled::FeatureDisabledError, Service::User::SignupVerify::InvalidTokenError => e
      raise Exceptions::UnprocessableEntity, e.message
    end

    current_user_set(user) if user

    msg = user ? { message: 'ok', user_email: user.email } : { message: 'failed' }

    render json: msg, status: :ok
  end

=begin

Resource:
POST /api/v1/users/email_verify_send

Payload:
{
  "email": "some_email@example.com"
}

Response:
{
  :message => 'ok'
}

Test:
curl http://localhost/api/v1/users/email_verify_send -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"email": "some_email@example.com"}'

=end

  def email_verify_send

    raise Exceptions::UnprocessableEntity, __('No email!') if !params[:email]

    signup = Service::User::Deprecated::Signup.new(user_data: { email: params[:email] }, resend: true)

    begin
      signup.execute
    rescue Service::CheckFeatureEnabled::FeatureDisabledError => e
      raise Exceptions::UnprocessableEntity, e.message
    rescue Service::User::Signup::TokenGenerationError
      render json: { message: 'failed' }, status: :ok
    end

    # Result is always positive to avoid leaking of existing user accounts.
    render json: { message: 'ok' }, status: :ok
  end

=begin

Resource:
POST /api/v1/users/admin_login

Payload:
{
  "username": "some user name"
}

Response:
{
  :message => 'ok'
}

Test:
curl http://localhost/api/v1/users/admin_login -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"username": "some_username"}'

=end

  def admin_password_auth_send
    raise Exceptions::UnprocessableEntity, 'username param needed!' if params[:username].blank?

    send = Service::Auth::Deprecated::SendAdminToken.new(login: params[:username])
    begin
      send.execute
    rescue Service::CheckFeatureEnabled::FeatureDisabledError => e
      raise Exceptions::UnprocessableEntity, e.message
    rescue Service::Auth::Deprecated::SendAdminToken::TokenError, Service::Auth::Deprecated::SendAdminToken::EmailError
      render json: { message: 'failed' }, status: :ok
      return
    end

    render json: { message: 'ok' }, status: :ok
  end

  def admin_password_auth_verify
    raise Exceptions::UnprocessableEntity, 'token param needed!' if params[:token].blank?

    verify = Service::Auth::VerifyAdminToken.new(token: params[:token])

    user = begin
      verify.execute
    rescue => e
      raise Exceptions::UnprocessableEntity, e.message
    end

    msg = user ? { message: 'ok', user_login: user.login } : { message: 'failed' }

    render json: msg, status: :ok
  end

=begin

Resource:
POST /api/v1/users/password_reset

Payload:
{
  "username": "some user name"
}

Response:
{
  :message => 'ok'
}

Test:
curl http://localhost/api/v1/users/password_reset -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"username": "some_username"}'

=end

  def password_reset_send
    raise Exceptions::UnprocessableEntity, 'username param needed!' if params[:username].blank?

    Service::User::PasswordReset::Deprecated::Send
      .new(username: params[:username])
      .execute

    # Result is always positive to avoid leaking of existing user accounts.
    render json: { message: 'ok' }, status: :ok
  rescue Service::CheckFeatureEnabled::FeatureDisabledError => e
    raise Exceptions::UnprocessableEntity, e.message
  end

=begin

Resource:
POST /api/v1/users/password_reset_verify

Payload:
{
  "token": "SoMeToKeN",
  "password": "new_pw"
}

Response:
{
  :message => 'ok'
}

Test:
curl http://localhost/api/v1/users/password_reset_verify -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"token": "SoMeToKeN", "password": "new_pw"}'

=end

  def password_reset_verify
    raise Exceptions::UnprocessableEntity, 'token param needed!' if params[:token].blank?

    # If no password is given, verify token only.
    if params[:password].blank?
      verify = Service::User::PasswordReset::Verify.new(token: params[:token])

      begin
        user = verify.execute
      rescue Service::CheckFeatureEnabled::FeatureDisabledError => e
        raise Exceptions::UnprocessableEntity, e.message
      rescue Service::User::PasswordReset::Verify::InvalidTokenError
        render json: { message: 'failed' }, status: :ok
        return
      end

      render json: { message: 'ok', user_login: user.login }, status: :ok
      return
    end

    update = Service::User::PasswordReset::Update.new(token: params[:token], password: params[:password])

    begin
      user = update.execute
    rescue Service::CheckFeatureEnabled::FeatureDisabledError => e
      raise Exceptions::UnprocessableEntity, e.message
    rescue Service::User::PasswordReset::Update::InvalidTokenError, Service::User::PasswordReset::Update::EmailError
      render json: { message: 'failed' }, status: :ok
      return
    rescue PasswordPolicy::Error => e
      render json: { message: 'failed', notice: e.metadata }, status: :ok
      return
    end

    render json: { message: 'ok', user_login: user.login }, status: :ok
  end

=begin

Resource:
POST /api/v1/users/password_change

Payload:
{
  "password_old": "old_pw",
  "password_new": "new_pw"
}

Response:
{
  :message => 'ok'
}

Test:
curl http://localhost/api/v1/users/password_change -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"password_old": "old_pw", "password_new": "new_pw"}'

=end

  def password_change
    # check old password
    if !params[:password_old] || !PasswordPolicy::MaxLength.valid?(params[:password_old])
      render json: { message: 'failed', notice: [__('Please provide your current password.')] }, status: :unprocessable_entity
      return
    end

    # set new password
    if !params[:password_new]
      render json: { message: 'failed', notice: [__('Please provide your new password.')] }, status: :unprocessable_entity
      return
    end

    begin
      Service::User::ChangePassword.new(
        user:             current_user,
        current_password: params[:password_old],
        new_password:     params[:password_new]
      ).execute
    rescue PasswordPolicy::Error => e
      render json: { message: 'failed', notice: e.metadata }, status: :unprocessable_entity
      return
    rescue PasswordHash::Error
      render json: { message: 'failed', notice: [__('The current password you provided is incorrect.')] }, status: :unprocessable_entity
      return
    end

    render json: { message: 'ok', user_login: current_user.login }, status: :ok
  end

  def password_check
    raise Exceptions::UnprocessableEntity, __("The required parameter 'password' is missing.") if params[:password].blank?

    password_check = Service::User::PasswordCheck.new(user: current_user, password: params[:password])

    render json: password_check.execute, status: :ok
  end

=begin

Resource:
PUT /api/v1/users/preferences

Payload:
{
  "language": "de",
  "notification": true
}

Response:
{
  :message => 'ok'
}

Test:
curl http://localhost/api/v1/users/preferences -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"language": "de", "notifications": true}'

=end

  def preferences
    preferences_params = params.except(:controller, :action)

    if preferences_params.present?
      user = User.find(current_user.id)
      user.with_lock do
        preferences_params.permit!.to_h.each do |key, value|
          user.preferences[key.to_sym] = value
        end
        user.save!
      end
    end
    render json: { message: 'ok' }, status: :ok
  end

=begin

Resource:
POST /api/v1/users/preferences_reset

Response:
{
  :message => 'ok'
}

Test:
curl http://localhost/api/v1/users/preferences_reset -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST'

=end

  def preferences_notifications_reset
    User.reset_notifications_preferences!(current_user)

    render json: { message: 'ok' }, status: :ok
  end

=begin

Resource:
PUT /api/v1/users/out_of_office

Payload:
{
  "out_of_office": true,
  "out_of_office_start_at": true,
  "out_of_office_end_at": true,
  "out_of_office_replacement_id": 123,
  "out_of_office_text": 'honeymoon'
}

Response:
{
  :message => 'ok'
}

Test:
curl http://localhost/api/v1/users/out_of_office -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"out_of_office": true, "out_of_office_replacement_id": 123}'

=end

  def out_of_office
    user = User.find(current_user.id)

    Service::User::OutOfOffice
      .new(user,
           enabled:     params[:out_of_office],
           start_at:    params[:out_of_office_start_at],
           end_at:      params[:out_of_office_end_at],
           replacement: User.find_by(id: params[:out_of_office_replacement_id]),
           text:        params[:out_of_office_text])
      .execute

    render json: { message: 'ok' }, status: :ok
  end

=begin

Resource:
DELETE /api/v1/users/account

Payload:
{
  "provider": "twitter",
  "uid": 581482342942
}

Response:
{
  :message => 'ok'
}

Test:
curl http://localhost/api/v1/users/account -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"provider": "twitter", "uid": 581482342942}'

=end

  def account_remove
    # provider + uid to remove
    raise Exceptions::UnprocessableEntity, 'provider needed!' if !params[:provider]
    raise Exceptions::UnprocessableEntity, 'uid needed!' if !params[:uid]

    Service::User::RemoveLinkedAccount.new(provider: params[:provider], uid: params[:uid], current_user:).execute

    render json: { message: 'ok' }, status: :ok
  end

=begin

Resource:
GET /api/v1/users/image/8d6cca1c6bdc226cf2ba131e264ca2c7

Response:
<IMAGE>

Test:
curl http://localhost/api/v1/users/image/8d6cca1c6bdc226cf2ba131e264ca2c7 -v -u #{login}:#{password}

=end

  def image
    # Cache images in the browser.
    expires_in(1.year.from_now, must_revalidate: true)

    file = Avatar.get_by_hash(params[:hash])

    if file
      file_content_type = file.preferences['Content-Type'] || file.preferences['Mime-Type']

      return serve_default_image if ActiveStorage.content_types_allowed_inline.exclude?(file_content_type)

      send_data(
        file.content,
        filename:    file.filename,
        type:        file_content_type,
        disposition: 'inline'
      )
      return
    end

    serve_default_image
  end

=begin

Resource:
POST /api/v1/users/avatar

Payload:
{
  "avatar_full": "base64 url",
}

Response:
{
  message: 'ok'
}

Test:
curl http://localhost/api/v1/users/avatar -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"avatar": "base64 url"}'

=end

  def avatar_new
    service = Service::Avatar::ImageValidate.new
    file_full = service.execute(image_data: params[:avatar_full])
    if file_full[:error].present?
      render json: { error: file_full[:message] }, status: :unprocessable_entity
      return
    end

    file_resize = service.execute(image_data: params[:avatar_resize])
    if file_resize[:error].present?
      render json: { error: file_resize[:message] }, status: :unprocessable_entity
      return
    end

    render json: { avatar: Service::Avatar::Add.new(current_user: current_user).execute(full_image: file_full, resize_image: file_resize) }, status: :ok
  end

  def avatar_set_default
    # get & validate image
    raise Exceptions::UnprocessableEntity, __("The required parameter 'id' is missing.") if !params[:id]

    # set as default
    avatar = Avatar.set_default('User', current_user.id, params[:id])

    # update user link
    user = User.find(current_user.id)
    user.update!(image: avatar.store_hash)

    render json: {}, status: :ok
  end

  def avatar_destroy
    # get & validate image
    raise Exceptions::UnprocessableEntity, __("The required parameter 'id' is missing.") if !params[:id]

    # remove avatar
    Avatar.remove_one('User', current_user.id, params[:id])

    # update user link
    if (avatar = Avatar.get_default('User', current_user.id))
      user = User.find(current_user.id)
      user.update!(image: avatar.store_hash)
    end

    render json: {}, status: :ok
  end

  def avatar_list
    # list of avatars
    result = Avatar.list('User', current_user.id)
    render json: { avatars: result }, status: :ok
  end

  # @path    [GET] /users/import_example
  #
  # @summary          Download of example CSV file.
  # @notes            The requester have 'admin.user' permissions to be able to download it.
  # @example          curl -u #{login}:#{password} http://localhost:3000/api/v1/users/import_example
  #
  # @response_message 200 File download.
  # @response_message 403 Forbidden / Invalid session.
  def import_example
    send_data(
      User.csv_example,
      filename:    'user-example.csv',
      type:        'text/csv',
      disposition: 'attachment'
    )
  end

  # @path    [POST] /users/import
  #
  # @summary          Starts import.
  # @notes            The requester have 'admin.text_module' permissions to be create a new import.
  # @example          curl -u #{login}:#{password} -F 'file=@/path/to/file/users.csv' 'https://your.zammad/api/v1/users/import?try=true'
  # @example          curl -u #{login}:#{password} -F 'file=@/path/to/file/users.csv' 'https://your.zammad/api/v1/users/import'
  #
  # @response_message 201 Import started.
  # @response_message 403 Forbidden / Invalid session.
  def import_start
    string = params[:data]
    if string.blank? && params[:file].present?
      string = params[:file].read.force_encoding('utf-8')
    end
    raise Exceptions::UnprocessableEntity, __('No source data submitted!') if string.blank?

    result = User.csv_import(
      string:       string,
      parse_params: {
        col_sep: params[:col_sep] || ',',
      },
      try:          params[:try],
      delete:       params[:delete],
    )
    render json: result, status: :ok
  end

  def two_factor_enabled_authentication_methods
    user = User.find(params[:id])

    render json: { methods: user.two_factor_enabled_authentication_methods }, status: :ok
  end

  private

  def password_login?
    return true if Setting.get('user_show_password_login')
    return true if Setting.where('name LIKE ? AND frontend = true', "#{SqlHelper.quote_like('auth_')}%")
      .map { |provider| provider.state_current['value'] }
      .all?(false)

    false
  end

  def clean_user_params
    User.param_cleanup(User.association_name_to_id_convert(params), true).merge(screen: 'create')
  end

  # @summary          Creates a User record with the provided attribute values.
  # @notes            For creating a user via agent interface
  #
  # @parameter        User(required,body) [User] The attribute value structure needed to create a User record.
  #
  # @response_message 200 [User] Created User record.
  # @response_message 403        Forbidden / Invalid session.
  def create_internal
    # permission check
    check_attributes_by_current_user_permission(params)

    user = User.new(clean_user_params)
    user.associations_from_param(params)

    user.save!

    if params[:invite].present?
      token = Token.create(action: 'PasswordReset', user_id: user.id)
      NotificationFactory::Mailer.notification(
        template: 'user_invite',
        user:     user,
        objects:  {
          token:        token,
          user:         user,
          current_user: current_user,
        }
      )
    end

    if response_expand?
      user = user.reload.attributes_with_association_names
      user.delete('password')
      render json: user, status: :created
      return
    end

    if response_full?
      result = {
        id:     user.id,
        assets: user.assets({}),
      }
      render json: result, status: :created
      return
    end

    user = user.reload.attributes_with_association_ids
    user.delete('password')
    render json: user, status: :created
  end

  # @summary          Creates a User record with the provided attribute values.
  # @notes            For creating a user via public signup form
  #
  # @parameter        User(required,body) [User] The attribute value structure needed to create a User record.
  #
  # @response_message 200 [User] Created User record.
  # @response_message 403        Forbidden / Invalid session.
  def create_signup
    # check signup option only after admin account is created
    if !params[:signup]
      raise Exceptions::UnprocessableEntity, __("The required parameter 'signup' is missing.")
    end

    # only allow fixed fields
    # TODO: https://github.com/zammad/zammad/issues/3295
    new_params = clean_user_params.slice(:firstname, :lastname, :email, :password)

    # check if user already exists
    if new_params[:email].blank?
      raise Exceptions::UnprocessableEntity, __("The required attribute 'email' is missing.")
    end

    signup = Service::User::Deprecated::Signup.new(user_data: new_params)

    begin
      signup.execute
    rescue PasswordPolicy::Error => e
      render json: { message: 'failed', notice: e.metadata }, status: :unprocessable_entity
      return
    rescue Service::CheckFeatureEnabled::FeatureDisabledError => e
      raise Exceptions::UnprocessableEntity, e.message
    end

    render json: { message: 'ok' }, status: :created
  end

  # @summary          Creates a User record with the provided attribute values.
  # @notes            For creating an administrator account when setting up the system
  #
  # @parameter        User(required,body) [User] The attribute value structure needed to create a User record.
  #
  # @response_message 200 [User] Created User record.
  # @response_message 403        Forbidden / Invalid session.
  def create_admin
    Service::User::AddFirstAdmin.new.execute(
      user_data: clean_user_params.slice(:firstname, :lastname, :email, :password),
      request:   request,
    )
    render json: { message: 'ok' }, status: :created
  rescue PasswordPolicy::Error => e
    render json: { message: 'failed', notice: e.metadata }, status: :unprocessable_entity
  rescue Exceptions::MissingAttribute, Service::System::CheckSetup::SystemSetupError => e
    raise Exceptions::UnprocessableEntity, e.message
  end

  def serve_default_image
    image = 'R0lGODdhMAAwAOMAAMzMzJaWlr6+vqqqqqOjo8XFxbe3t7GxsZycnAAAAAAAAAAAAAAAAAAAAAAAAAAAACwAAAAAMAAwAAAEcxDISau9OOvNu/9gKI5kaZ5oqq5s675wLM90bd94ru98TwuAA+KQAQqJK8EAgBAgMEqmkzUgBIeSwWGZtR5XhSqAULACCoGCJGwlm1MGQrq9RqgB8fm4ZTUgDBIEcRR9fz6HiImKi4yNjo+QkZKTlJWWkBEAOw=='

    send_data(
      Base64.decode64(image),
      filename:    'image.gif',
      type:        'image/gif',
      disposition: 'inline'
    )
  end
end
