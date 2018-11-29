module ZendeskAPI
  # Creates put, post, delete class methods for custom resource methods.
  module Verbs
    class << self
      private

      # @macro [attach] container.create_verb
      #   @method $1(method)
      #   Executes a $1 using the passed in method as a path.
      #   Reloads the resource's attributes if any are in the response body.
      #
      #   Created method takes an optional options hash. Valid options to be passed in to the created method: reload (for caching, default: false)
      def create_verb(method_verb)
        define_method method_verb do |method|
          define_method "#{method}!" do |*method_args|
            opts = method_args.last.is_a?(Hash) ? method_args.pop : {}

            if method_verb == :any
              verb = opts.delete(:verb)
              raise(ArgumentError, ":verb required for method defined as :any") unless verb
            else
              verb = method_verb
            end

            @response = @client.connection.send(verb, "#{path}/#{method}") do |req|
              req.body = opts
            end

            return false unless @response.success?
            return false unless @response.body

            resource = nil

            if @response.body.is_a?(Hash)
              resource = @response.body[self.class.singular_resource_name]
              resource ||= @response.body.fetch(self.class.resource_name, []).detect { |res| res["id"] == id }
            end

            @attributes.replace @attributes.deep_merge(resource || {})
            @attributes.clear_changes
            clear_associations

            true
          end

          define_method method do |*method_args|
            begin
              send("#{method}!", *method_args)
            rescue ZendeskAPI::Error::RecordInvalid => e
              @errors = e.errors
              false
            rescue ZendeskAPI::Error::ClientError
              false
            end
          end
        end
      end
    end

    create_verb :put
    create_verb :post
    create_verb :delete
    create_verb :any
  end
end
