# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module ActiveRecord::Locking::Pessimistic

  # https://github.com/zammad/zammad/issues/3664
  #
  # With Zammad 5.2 and Rails update from 6.1.6.2 to 6.1.7, internal database storage format
  #   of preferences columns changed from serialized `ActiveSupport::HashWithIndifferentAccess` to just serialized `Hash``.
  # The downside is that 'old' values still have the old format, and show up as changed, which prevents
  #   `with_lock` from working correctly - it would throw errors on previously modified records,
  #   making tickets/users non-updateable.
  # We work around this by suppressing the exception in just this case.
  if !method_defined?(:orig_lock!)

    alias orig_lock! lock!

    def lock!(lock = true) # rubocop:disable Style/OptionalBooleanParameter
      if persisted? && has_changes_to_save?

        # We will skip the exception in case if the changes only contain columns which are store-type and have idential value.
        skip_exception = changes.all? do |key, value|
          send(key.to_sym).instance_of?(ActiveSupport::HashWithIndifferentAccess) && Marshal.dump(value[0]) == Marshal.dump(value[1])
        end

        if skip_exception
          reload(lock: lock)
          return self
        end
      end

      orig_lock!(lock)
    end
  end
end
