# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module CanSeed
  extend ActiveSupport::Concern

  # methods defined here are going to extend the class, not the instance of it
  class_methods do

    def reseed
      destroy_all
      seed
    end

    def seed
      UserInfo.ensure_current_user_id do
        load seedfile
      end
    end

    def seedfile
      Rails.root.join('db', 'seeds', "#{name.pluralize.underscore.tr('/', '_')}.rb").to_s
    end
  end
end
