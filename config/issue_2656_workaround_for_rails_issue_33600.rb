# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# This temporary workaround for issue #2656.
# The root cause is an issue in Rails: https://github.com/rails/rails/issues/33600
# It disables database connnection reaping by setting `reaping_frequency` to 0 for each environment in the config/database.yml file.
# It restores the DB connection reaping behavior Rails > 5.2 had.
# It was proposed in a comment on the Rails issue: https://github.com/rails/rails/issues/33600#issuecomment-415395901
# It was confirmed by @matthewd (a Rails core maintainer) in another comment: https://github.com/rails/rails/issues/33600#issuecomment-415400522
module Rails
  class Application
    class Configuration < ::Rails::Engine::Configuration

      alias database_configuration_original database_configuration

      def database_configuration
        database_configuration_original&.transform_values do |config|
          config.merge(
            'reaping_frequency' => 0
          )
        end
      end
    end
  end
end
