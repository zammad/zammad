# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  module OTRS
    module UserFactory
      extend Import::Factory

      # rubocop:disable Style/ModuleFunction
      extend self

      # skip root@localhost since we have our own \o/
      def skip?(record, *_args)
        record['UserID'].to_i == 1
      end
    end
  end
end
