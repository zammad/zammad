# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Gql::ZammadSchema < GraphQL::Schema
  mutation      Gql::EntryPoints::Mutations
  query         Gql::EntryPoints::Queries
  subscription  Gql::EntryPoints::Subscriptions
  context_class Gql::Context::CurrentUserAware

  use GraphQL::Subscriptions::ActionCableSubscriptions, broadcast: true, default_broadcastable: false

  # Enable batch loading
  use GraphQL::Batch

  description 'This is the Zammad GraphQL API'

  # Set maximum page size and depth to protect the system.
  #   Values may need to be adjusted in future.
  default_max_page_size 1000

  # The GraphQL introspection query has a depth of 13, so allow that in the development env.
  max_depth Rails.env.eql?('development') ? 13 : 10

  TYPE_MAP = {
    ::Store => ::Gql::Types::StoredFileType
  }.freeze

  # Union and Interface Resolution
  def self.resolve_type(_abstract_type, obj, _ctx)
    TYPE_MAP[obj.class] || "Gql::Types::#{obj.class.name}Type".constantize
  rescue
    raise GraphQL::RequiredImplementationMissingError, "Cannot resolve type for '#{obj.class.name}'."
  end

  # Relay-style Object Identification:

  # Return a string UUID for the internal ID.
  def self.id_from_internal_id(klass, internal_id)
    GlobalID.new(::URI::GID.build(app: GlobalID.app, model_name: klass.to_s, model_id: internal_id)).to_s
  end

  # Return a string UUID for `object`
  def self.id_from_object(object, _type_definition = nil, _query_ctx = nil)
    object.to_global_id.to_s
  end

  # Given a string UUID, find the object.
  def self.object_from_id(id, _query_ctx = nil, type: ActiveRecord::Base)
    GlobalID.find(id, only: type)
  end

  # Find the object, but also ensure its type and that it was actually found.
  def self.verified_object_from_id(id, type:)
    object_from_id(id, type: type) || raise(ActiveRecord::RecordNotFound, "Could not find #{type} #{id}")
  end

  # Like .verified_object_from_id, but with additional Pundit autorization.
  #   This is only needed for objects where no validation takes place through their GraphQL type.
  def self.authorized_object_from_id(id, type:, user:, query: :show?)
    verified_object_from_id(id, type: type).tap do |object|
      Pundit.authorize user, object, query
    rescue Pundit::NotAuthorizedError => e
      # Map Pundit errors since we are not in a GraphQL built-in authorization context here.
      raise Exceptions::Forbidden, e.message
    end
  end

  def self.unauthorized_object(error)
    raise Exceptions::Forbidden, error.message # Add a top-level error to the response instead of returning nil.
  end

  def self.unauthorized_field(error)
    raise Exceptions::Forbidden, error.message # Add a top-level error to the response instead of returning nil.
  end

  RETHROWABLE_ERRORS = [ArgumentError, IndexError, NameError, RangeError, RegexpError, SystemCallError, ThreadError, TypeError, ZeroDivisionError].freeze

  # Post-process errors and enrich them with meta information for processing on the client side.
  rescue_from(StandardError) do |err, _obj, _args, ctx, field|
    if field&.path&.start_with?('Mutations.')
      user_locale = ctx.current_user?&.locale
      if err.is_a? ActiveRecord::RecordInvalid
        user_errors = err.record.errors.map { |e| { field: e.attribute.to_s.camelize(:lower), message: e.localized_full_message(locale: user_locale, no_field_name: true) } }
        next { errors: user_errors }
      end
      if err.is_a? ActiveRecord::RecordNotUnique
        next { errors: [ message: Translation.translate(user_locale, 'This object already exists.') ] }
      end
    end

    # Re-throw built-in errors that point to programming errors rather than problems with input or data - causes GraphQL processing to be aborted.
    RETHROWABLE_ERRORS.each do |klass|
      raise err if err.is_a? klass
    end

    extensions = {
      type: err.class.name,
    }
    if Rails.env.development? || Rails.env.test?
      extensions[:backtrace] = Rails.backtrace_cleaner.clean(err.backtrace)
    end

    # We need to throw an ExecutionError, all others would cause the GraphQL processing to die.
    raise GraphQL::ExecutionError.new(err.message, extensions: extensions)
  end
end

# Temporary Hack: only process trigger events if ActionCable is enabled.
# TODO: Remove when this switch is not needed any more.
module GraphQL
  class Subscriptions # rubocop:disable GraphQL/ObjectDescription
    if !method_defined?(:orig_trigger)
      alias orig_trigger trigger
      def trigger(...)
        return if ENV['ENABLE_EXPERIMENTAL_MOBILE_FRONTEND'] != 'true'

        orig_trigger(...)
      end
    end
  end
end
