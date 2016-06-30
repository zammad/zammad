# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Job
  module Assets

=begin

get all assets / related models for this job

  job = Job.find(123)
  result = job.assets(assets_if_exists)

returns

  result = {
    :jobs => {
      123  => job_model_123,
      1234 => job_model_1234,
    }
  }

=end

    def assets (data)

      if !data[ Job.to_app_model ]
        data[ Job.to_app_model ] = {}
      end
      if !data[ User.to_app_model ]
        data[ User.to_app_model ] = {}
      end
      if !data[ Job.to_app_model ][ id ]
        data[ Job.to_app_model ][ id ] = attributes_with_associations
        data = assets_of_selector('condition', data)
        data = assets_of_selector('perform', data)
      end
      %w(created_by_id updated_by_id).each { |local_user_id|
        next if !self[ local_user_id ]
        next if data[ User.to_app_model ][ self[ local_user_id ] ]
        user = User.lookup(id: self[ local_user_id ])
        next if !user
        data = user.assets(data)
      }
      data
    end
  end
end
