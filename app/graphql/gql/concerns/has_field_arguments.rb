# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Concerns::HasFieldArguments
  extend ActiveSupport::Concern

  included do
    # Shortcut to pass arguments to many fields in the enclosed block.
    #
    # field_args(my_arg: 'value') do  # All fields will be passed `my_arg: 'value'`
    #   field :my_field, ...
    #   field :other_field, ...
    # end
    def self.field_args(**kwargs)
      @additional_field_args = kwargs
      yield
    ensure
      @additional_field_args = nil
    end

    # Wrapper for the default `field` method that handles the additional arguments
    def self.field(*args, **kwargs, &block)
      super(*args, **kwargs, **(@additional_field_args || {}), &block)
    end
  end
end
