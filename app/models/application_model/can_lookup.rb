# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
module ApplicationModel::CanLookup
  extend ActiveSupport::Concern

  # methods defined here are going to extend the class, not the instance of it
  class_methods do

=begin

lookup model from cache (if exists) or retrieve it from db, id, name, login or email possible

  result = Model.lookup(id: 123)
  result = Model.lookup(name: 'some name')
  result = Model.lookup(login: 'some login')
  result = Model.lookup(email: 'some login')

returns

  result = model # with all attributes

=end

    def lookup(data)
      if data[:id]
        cache = cache_get(data[:id])
        return cache if cache

        record = find_by(id: data[:id])
        cache_set(data[:id], record)
        return record
      elsif data[:name]
        cache = cache_get(data[:name])
        return cache if cache

        # do lookup with == to handle case insensitive databases
        records = if Rails.application.config.db_case_sensitive
                    where('LOWER(name) = LOWER(?)', data[:name])
                  else
                    where(name: data[:name])
                  end
        records.each { |loop_record|
          if loop_record.name == data[:name]
            cache_set(data[:name], loop_record)
            return loop_record
          end
        }
        return
      elsif data[:login]
        cache = cache_get(data[:login])
        return cache if cache

        # do lookup with == to handle case insensitive databases
        records = if Rails.application.config.db_case_sensitive
                    where('LOWER(login) = LOWER(?)',  data[:login])
                  else
                    where(login: data[:login])
                  end
        records.each { |loop_record|
          if loop_record.login == data[:login]
            cache_set(data[:login], loop_record)
            return loop_record
          end
        }
        return
      elsif data[:email]
        cache = cache_get(data[:email])
        return cache if cache

        # do lookup with == to handle case insensitive databases
        records = if Rails.application.config.db_case_sensitive
                    where('LOWER(email) = LOWER(?)',  data[:email])
                  else
                    where(email: data[:email])
                  end
        records.each { |loop_record|
          if loop_record.email == data[:email]
            cache_set(data[:email], loop_record)
            return loop_record
          end
        }
        return
      end

      raise ArgumentError, 'Need name, id, login or email for lookup()'
    end
  end
end
