# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ZammadSpecSupportRequest

  # This ruby meta programming action creates the methods to perform:
  # GET, POST, PATCH, PUT, DELETE and HEAD
  # HTTP "requests".
  # They overwrite the ones of `ActionDispatch::Integration::RequestHelpers`
  # to add the headers set by #add_headers before
  %i[get post patch put delete head].each do |method_id|

    define_method(method_id) do |path, **args|
      args = args.with_indifferent_access
      args[:headers] = Hash(args[:headers]).merge!(Hash(@headers))
      super(path, **args.symbolize_keys)
    end
  end

  # Adds one or more HTTP headers to all requests of the current example.
  #
  # @param [Hash{String => String}] headers Hash of HTTP headers
  #
  # @example
  #  add_headers('Eg Some X-Header' => 'Some value')

  # @example
  #  add_headers(
  #    'Header 1' => 'Some value',
  #    'Header 2' => 'Some value',
  #    ...
  #  )
  #
  # @return [Hash] The current headers Hash
  def add_headers(headers)
    @headers = Hash(@headers).merge(headers)
  end

  # Parses the response.body as JSON.
  #
  # @example
  #  json_response

  # @example
  #  json_response.is_a?(Array)
  #
  # @return [Array, Hash, ...] Parsed JSON structure as Ruby object
  def json_response
    JSON.parse(response.body)
  end

  # Authenticates all requests of the current example as the given user.
  #
  # @example
  #  authenticated_as(some_admin_user)
  #
  # @example
  #  authenticated_as(some_admin_user, on_behalf_of: customer_user)
  #
  # @example
  #  authenticated_as(some_admin_user, password: 'wrongpw')
  #
  # @example
  #  authenticated_as(some_admin_user, password: 'wrongpw', token: create(:token, action: 'api', user_id: some_admin_user.id) )
  #
  # @example
  #  authenticated_as(nil, login: 'not_existing', password: 'wrongpw' )
  #
  # @return nil
  def authenticated_as(user, via: :api_client, **options)
    password = options[:password] || user.password.to_s
    login    = options[:login] || user.login

    # mock authentication otherwise login won't
    # if user has no password (which is expensive to create)
    if password.blank?
      allow(User).to receive(:authenticate).with(login, '') { user.update_last_login }.and_return(user)
    end

    case via
    when :api_client
      # ensure that always the correct header value is set
      # otherwise previous header configurations will be re-used
      add_headers('X-On-Behalf-Of' => options[:on_behalf_of])

      # if we want to authenticate by token
      credentials = if options[:token].present?
                      "Token token=#{options[:token].name}"
                    else
                      ActionController::HttpAuthentication::Basic.encode_credentials(login, password)
                    end

      add_headers('Authorization' => credentials)
    when :browser
      post '/api/v1/signin', params: { username: login, password: password, fingerprint: Faker::Number.number(9) }
    end
  end

  # Provides a Hash of attributes for the given FactoryBot
  #  factory parameters which can be used as the params payload.
  #  Note that the attributes are "cleaned" so no created_by_id etc.
  #  is present.
  #
  # @see FactoryBot#attributes_for
  #
  # @example
  #  attributes_params_for(:admin, email: 'custom@example.com')
  #  # => {firstname: 'Nicole', email: 'custom@example.com', ...}
  #
  # @return [Hash{Symbol => <String, Array, Hash>}] request cleaned attributes
  def attributes_params_for(*args)
    filter_unused_params(attributes_for(*args))
  end

  # Provides a Hash of attributes for the given Model instance which can
  #  be used as the params payload.
  #  Note that the attributes are "cleaned" so no created_by_id etc.
  #  is present.
  #
  # @param [Hash] instance An ActiveRecord instance
  #
  # @example
  #  cleaned_params_for(some_admin_user)
  #  # => {firstname: 'Nicole', email: 'admin@example.com', ...}
  #
  # @return [Hash{Symbol => <String, Array, Hash>}] request cleaned attributes
  def cleaned_params_for(instance)
    filter_unused_params(instance.attributes)
  end

  # This is a self explaining internal method.
  #
  # @see ApplicationModel#filter_unused_params
  def filter_unused_params(unfiltered)
    # let's get private
    ApplicationModel.send(:filter_unused_params, unfiltered)
  end
end

RSpec.configure do |config|
  config.include ZammadSpecSupportRequest, type: :request

  config.before(:each, type: :request) do
    Setting.set('system_init_done', true)
  end

  # This helper allows you to authenticate as a given user in request specs
  # via the example metadata, rather than directly:
  #
  #     it 'does something', authenticated_as: :user
  #
  # In order for this to work, you must define the user in a `let` block first:
  #
  #     let(:user) { create(:customer) }
  #
  config.before(:each, :authenticated_as, type: :request) do |example|
    user = authenticated_as_get_user example.metadata[:authenticated_as], return_type: :user

    authenticated_as user if user
  end
end
