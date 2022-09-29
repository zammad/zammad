# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module ActiveRecord
  module Locking
    module Pessimistic
      def lock!(lock = true) # rubocop:disable Style/OptionalBooleanParameter, Metrics/AbcSize
        if persisted?
          if has_changes_to_save?
            # ---
            # Zammad
            # ---
            # https://github.com/zammad/zammad/issues/3664

            # We will skip the exception in case if the changes
            # only include columns which are store-type
            skip_exception = changes.all? do |key, value|
              send(key.to_sym).instance_of?(ActiveSupport::HashWithIndifferentAccess) && Marshal.dump(value[0]) == Marshal.dump(value[1])
            end

            if skip_exception
              reload(lock: lock)
              return self
            end
            # ---
            raise(<<-MSG.squish)
              Locking a record with unpersisted changes is not supported. Use
              `save` to persist the changes, or `reload` to discard them
              explicitly.
              Changed attributes: #{changed.map(&:inspect).join(', ')}.
            MSG
          end

          reload(lock: lock)
        end
        self
      end
    end
  end
end
