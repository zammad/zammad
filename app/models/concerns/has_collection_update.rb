# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module HasCollectionUpdate
  extend ActiveSupport::Concern

  included do
    after_commit :push_collection_to_clients
  end

  # methods defined here are going to extend the class, not the instance of it
  class_methods do

=begin

define required permissions to push collection to web app

class Model < ApplicationModel
  include HasCollectionUpdate
  collection_push_permission('some_permission')
end

=end
    attr_accessor :collection_push_permission_value

    def collection_push_permission(*permission)
      @collection_push_permission_value = permission
    end
  end

  def push_collection_to_clients
    return if Setting.get('import_mode')

    CollectionUpdateJob.set(wait: 10.seconds).perform_later(self.class.name)
  end
end
