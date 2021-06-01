# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ActiveSupport::Callbacks::ClassMethods
  # Performs actions on a ActiveSupport model without triggering the given callback.
  # The parameters are the same as for `skip_callback` and `set_callback`:
  # http://api.rubyonrails.org/classes/ActiveSupport/Callbacks/ClassMethods.html
  #
  # Keep in mind that variables defined inside the block are only valid there. If you need
  # to access one after the block has been processed make sure to initialize the variable
  # before the block. This is the same behaviour as for all blocks.
  #
  # ATTENTION: This is not thread-safe and should not be used in threaded environment.
  #
  # @param name [Symbol] The name of the callback like e.g. :save
  # @param when [Symbol] Indicates the time when the callback should run like e.g. :before
  # @param method [Symbol] The name of the method that should get disabled e.g. :some_example_method
  #
  # @example
  #  User.without_callback(:create, :after, :avatar_for_email_check) do
  #    User.create(...)
  #    'example return value'
  #  end
  #  #=> 'example return value'
  #
  # @return [optional] Returns the return value of the given block
  def without_callback(*args)
    begin
      skip_callback(*args)
      result = yield
    ensure
      set_callback(*args)
    end
    result
  end
end
