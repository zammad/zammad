# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Job
  module Assets
    extend ActiveSupport::Concern

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

    def assets(data)

      app_model_job = Job.to_app_model
      data[ app_model_job ] ||= {}

      return data if data[ app_model_job ][ id ]

      data[ app_model_job ][ id ] = attributes_with_association_ids
      data = assets_of_selector('condition', data)
      data = assets_of_selector('perform', data)

      app_model_user = User.to_app_model
      data[ app_model_user ] ||= {}

      %w[created_by_id updated_by_id].each do |local_user_id|
        next if !self[ local_user_id ]
        next if data[ app_model_user ][ self[ local_user_id ] ]

        user = User.lookup(id: self[ local_user_id ])
        next if !user

        data = user.assets(data)
      end
      data
    end
  end
end
