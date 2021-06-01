# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ApplicationModel::HasExistsCheckByObjectAndId
  extend ActiveSupport::Concern

  class_methods do

=begin

verify if referenced object exists

  success = Model.exists_by_object_and_id('Ticket', 123)

returns

  # true or will raise an exception

=end

    def exists_by_object_and_id?(object, o_id)

      begin
        local_class = object.constantize
      rescue => e
        raise "Unable for get an instance of '#{object}': #{e.inspect}"
      end
      if !local_class.exists?(o_id)
        raise ActiveRecord::RecordNotFound, "Unable for find reference object '#{object}.exists?(#{o_id})!"
      end

      true
    end

  end

end
