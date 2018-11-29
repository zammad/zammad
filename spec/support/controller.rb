module ZammadSpecSupportController

  # Authenticates all requests of the current example as the given user.
  #
  # @example
  #  authenticated_as(some_admin_user)
  #
  # @return nil
  def authenticated_as(user)
    session[:user_id] = user.id
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

  def self.included(base)

    # Execute in RSpec class context
    base.class_exec do

      # This method disables the CSRF token validation for all controller
      #  examples. It's possible to re-enable the check by adding the
      #  meta tag `verify_csrf_token` to the needing example:
      #
      # @example
      #  it 'does stuff with verified CSRF token', verify_csrf_token: true do
      #
      before(:each) do |example|
        if !example.metadata[:verify_csrf_token]
          allow(controller).to receive(:verify_csrf_token).and_return(true)
        end
      end

      # This method disables the user device check for all controller
      #  examples. It's possible to re-enable the check by adding the
      #  meta tag `perform_user_device_check` to the needing example:
      #
      # @example
      #  it 'does stuff with user device check', perform_user_device_check: true do
      #
      before(:each) do |example|
        if !example.metadata[:perform_user_device_check]
          session[:user_device_updated_at] = Time.zone.now
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include ZammadSpecSupportController, type: :controller
end
