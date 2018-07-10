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
  # @return nil
  def authenticated_as(user)
    # mock authentication otherwise login won't
    # if user has no password (which is expensive to create)
    if user.password.nil?
      allow(User).to receive(:authenticate).with(user.login, '').and_return(user)
    end

    credentials = ActionController::HttpAuthentication::Basic.encode_credentials(user.login, user.password)
    add_headers('Authorization' => credentials)
  end

  # Provides a Hash of attributes for the given FactoryBot
  #  factory parameters which can be used as the params payload.
  #  Note that the attributes are "cleaned" so no created_by_id etc.
  #  is present.
  #
  # @see FactoryBot#attributes_for
  #
  # @example
  #  attributes_params_for(:admin_user, email: 'custom@example.com')
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
end
