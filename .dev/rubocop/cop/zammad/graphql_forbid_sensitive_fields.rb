# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module RuboCop
  module Cop
    module Zammad
      class GraphqlForbidSensitiveFields < Base
        MSG = 'Avoid declaring sensitive field `:%{name}` in a GraphQL return type — it may leak secrets to the API consumer. Use `# rubocop:disable Zammad/GraphqlForbidSensitiveFields` with a justification if intentional.'.freeze

        # Inspired by config/initializers/filter_parameter_logging.rb.
        # Matched as substrings against the (snake_case) field name —
        # `passw` therefore also catches `password`/`passwd`, and `cert`
        # also catches `certificate`. The `_key` substring from the Rails
        # filter list is too broad for a static check (e.g. `cache_key`,
        # `foreign_key`), so concrete sensitive `_key` names are listed.
        SENSITIVE_SUBSTRINGS = %w[
          passw
          passphrase
          secret
          token
          api_key
          private_key
          auth_key
          access_key
          master_key
          signing_key
          crypt
          salt
          cert
          otp
          ssn
          cvv
          cvc
          credential
          bind_pw
        ].freeze

        # Match `field` and the relation helpers in HasModelRelations
        # (belongs_to/has_one/lookup_field), which all forward to `field`
        # under the hood and therefore also expose a return-type field.
        def_node_matcher :graphql_field?, <<~PATTERN
          (send nil? {:field :belongs_to :has_one :lookup_field} (sym $_) ...)
        PATTERN

        def on_send(node)
          graphql_field?(node) do |field_name|
            name_string = field_name.to_s
            next if SENSITIVE_SUBSTRINGS.none? { |needle| name_string.include?(needle) } # rubocop:disable Style/ArrayIntersect

            add_offense(node.first_argument, message: format(MSG, name: name_string))
          end
        end
      end
    end
  end
end
