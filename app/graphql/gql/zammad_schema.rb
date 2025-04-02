# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Gql::ZammadSchema < GraphQL::Schema
  mutation      Gql::EntryPoints::Mutations
  query         Gql::EntryPoints::Queries
  subscription  Gql::EntryPoints::Subscriptions
  context_class Gql::Context::CurrentUserAware

  use GraphQL::Subscriptions::ActionCableSubscriptions, broadcast: true, default_broadcastable: false
  use GraphQL::Batch
  use GraphQL::FragmentCache

  description 'This is the Zammad GraphQL API'

  # Set default limits to protect the system. Values may need to be adjusted in future.
  default_max_page_size 2000
  default_page_size 100
  max_complexity 10_000

  max_depth 8, count_introspection_fields: false

  # Required for loads:, other types like unions need to implement type resolution directly.
  def self.resolve_type(abstract_type, _obj, _ctx)
    abstract_type
  end

  # Relay-style Object Identification:

  # Return a string GUID for the internal ID.
  def self.id_from_internal_id(klass, internal_id)
    GlobalID.new(::URI::GID.build(app: GlobalID.app, model_name: klass.to_s, model_id: internal_id)).to_s
  end

  # Return a string GUID for `object`
  def self.id_from_object(object, _type_definition = nil, _query_ctx = nil)
    object.to_global_id.to_s
  end

  # Given a string GUID, find the object.
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
      Pundit.authorize(user, object, query)
    rescue Pundit::NotAuthorizedError => e
      # Map Pundit errors since we are not in a GraphQL built-in authorization context here.
      raise Exceptions::Forbidden, e.message
    end
  end

  # Given a string GUID, extract the internal ID.
  # This is very helpful if GUIDs have to be converted en-masse and then authorized in bulk using a scope.
  # Meanwhile using .object_from_id family would load (and, optionally, authorize) objects one by one.
  # Beware there's no built-in way to authorize given IDs in this method!
  #
  # @param id [String] GUID
  # @param type [Class] optionally filter to specific class only
  #
  # @return [Integer, nil]
  def self.internal_id_from_id(id, type: ActiveRecord::Base)
    internal_ids_from_ids([id], type:).first
  end

  # Given an array of string GUIDs, extract the internal IDs
  # @see .internal_id_from_id
  #
  # @param ids [Array<String>] GUIDs
  # @param type [Class] optionally filter to specific class only
  #
  # @return [Array<Integer>]
  def self.internal_ids_from_ids(...)
    local_uris_from_ids(...).map { |uri| uri.model_id.to_i }
  end

  # Given an array of string GUIDs, return GUID instances
  #
  # @param ids [Array<String>] GUIDs
  # @param type [Class] optionally filter to specific class only
  #
  # @return [Array<GlobalID>]
  def self.local_uris_from_ids(ids, type: ActiveRecord::Base)
    ids
      .map { |id| GlobalID.parse id }
      .select { |uri| (klass = uri.model_name.safe_constantize) && klass <= type }
  end

  def self.unauthorized_object(error)
    raise Exceptions::Forbidden, error.message # Add a top-level error to the response instead of returning nil.
  end

  def self.unauthorized_field(error)
    raise Exceptions::Forbidden, error.message # Add a top-level error to the response instead of returning nil.
  end

  RETHROWABLE_ERRORS = [GraphQL::ExecutionError, ArgumentError, IndexError, NameError, NoMethodError, RangeError, RegexpError, SystemCallError, ThreadError, TypeError, ZeroDivisionError].freeze

  # Post-process errors and enrich them with meta information for processing on the client side.
  rescue_from(StandardError) do |err, _obj, _args, ctx, field|
    if field&.path&.start_with?('Mutations.')
      user_locale = ctx.current_user?&.locale

      case err
      when ActiveRecord::RecordInvalid
        next { errors: build_record_invalid_errors(err.record, user_locale) }
      when ActiveRecord::RecordNotUnique
        next { errors: [ message: Translation.translate(user_locale, 'This object already exists.') ] }
      end
    end

    # Re-throw built-in errors that point to programming errors rather than problems with input or data - causes GraphQL processing to be aborted.
    RETHROWABLE_ERRORS.each do |klass|
      raise err if err.instance_of?(klass)
    end

    extensions = {
      type: err.class.name,
    }
    if Rails.env.local?
      extensions[:backtrace] = Rails.backtrace_cleaner.clean(err.backtrace)
    end

    # We need to throw an ExecutionError, all others would cause the GraphQL processing to die.
    raise GraphQL::ExecutionError.new(err.message, extensions: extensions)
  end

  def self.build_record_invalid_errors(record, user_locale)
    record.errors.map do |e|
      field_name = e.attribute.to_s.camelize(:lower)

      {
        field:   field_name == 'base' ? nil : field_name,
        message: e.localized_full_message(locale: user_locale, no_field_name: true)
      }
    end
  end
  private_class_method :build_record_invalid_errors
end
