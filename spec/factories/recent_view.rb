FactoryBot.define do
  factory :recent_view do
    transient do
      type { :ticket }
      user_role { :agent }
    end

    recent_view_object_id { ObjectLookup.by_name(type.to_s.camelcase) }

    # select a random record of the given object class
    o_id do
      random_function = case ActiveRecord::Base.connection_config[:adapter]
                        when 'mysql2'
                          'RAND'
                        when 'postgresql'
                          'RANDOM'
                        end

      type.to_s.camelcase.constantize.order("#{random_function}()").first.id
    end

    # assign to an existing user, if possible
    created_by_id do
      User.find { |u| u.role?(user_role.capitalize) }&.id ||
        create("#{user_role}_user").id
    end
  end
end
