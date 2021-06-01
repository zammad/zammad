# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  module OTRS
    module PriorityFactory
      extend Import::Factory

      # rubocop:disable Style/ModuleFunction
      extend self

      def import_loop(records, *_args, &import_block)
        super
        update_attribute_settings
      end

      def update_attribute_settings
        return if Import::OTRS.diff?

        update_attribute
      end

      def update_attribute
        priority = ::Ticket::Priority.find_by(
          name:   Import::OTRS::SysConfigFactory.postmaster_default_lookup(:priority_default_create),
          active: true
        )
        return if !priority

        priority.default_create = true
        priority.callback_loop  = true

        priority.save
      end
    end
  end
end
