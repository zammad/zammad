# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# JSON column type that behaves like the former YAML store columns: values are always
# hashes with indifferent access, so symbol and string keys work alike.
module ActiveRecord
  module Type
    class IndifferentJson < ActiveRecord::Type::Json
      def deserialize(value)
        # YAML of the former store columns, present until the conversion migration ran
        return ActiveRecord::Store::IndifferentCoder.as_indifferent_hash(YAML.unsafe_load(value)) if value.is_a?(::String) && value.start_with?('---')

        ActiveRecord::Store::IndifferentCoder.as_indifferent_hash(super)
      end

      # mixed symbol and string keys would be duplicate JSON keys
      def serialize(value)
        super(ActiveRecord::Store::IndifferentCoder.as_indifferent_hash(value))
      end
    end

    register(:indifferent_json, IndifferentJson)
  end
end
