# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
module ApplicationModel::CanCreatesAndUpdates
  extend ActiveSupport::Concern

  # methods defined here are going to extend the class, not the instance of it
  class_methods do

=begin

create model if not exists (check exists based on id, name, login, email or locale)

  result = Model.create_if_not_exists(attributes)

returns

  result = model # with all attributes

=end

    def create_if_not_exists(data)
      if data[:id]
        record = find_by(id: data[:id])
        return record if record
      elsif data[:name]

        # do lookup with == to handle case insensitive databases
        records = if Rails.application.config.db_case_sensitive
                    where('LOWER(name) = LOWER(?)', data[:name])
                  else
                    where(name: data[:name])
                  end
        records.each do |loop_record|
          return loop_record if loop_record.name == data[:name]
        end
      elsif data[:login]

        # do lookup with == to handle case insensitive databases
        records = if Rails.application.config.db_case_sensitive
                    where('LOWER(login) = LOWER(?)', data[:login])
                  else
                    where(login: data[:login])
                  end
        records.each do |loop_record|
          return loop_record if loop_record.login == data[:login]
        end
      elsif data[:email]

        # do lookup with == to handle case insensitive databases
        records = if Rails.application.config.db_case_sensitive
                    where('LOWER(email) = LOWER(?)', data[:email])
                  else
                    where(email: data[:email])
                  end
        records.each do |loop_record|
          return loop_record if loop_record.email == data[:email]
        end
      elsif data[:locale] && data[:source]

        # do lookup with == to handle case insensitive databases
        records = if Rails.application.config.db_case_sensitive
                    where('LOWER(locale) = LOWER(?) AND LOWER(source) = LOWER(?)', data[:locale], data[:source])
                  else
                    where(locale: data[:locale], source: data[:source])
                  end
        records.each do |loop_record|
          return loop_record if loop_record.source == data[:source]
        end
      end
      create(data)
    end

=begin

Model.create_or_update with ref lookups

  result = Model.create_or_update(attributes)

returns

  result = model # with all attributes

=end

    def create_or_update_with_ref(data)
      data = association_name_to_id_convert(data)
      create_or_update(data)
    end

=begin

Model.create_if_not_exists with ref lookups

  result = Model.create_if_not_exists_with_ref(attributes)

returns

  result = model # with all attributes

=end

    def create_if_not_exists_with_ref(data)
      data = association_name_to_id_convert(data)
      create_or_update(data)
    end

=begin

create or update model (check exists based on id, name, login, email or locale)

  result = Model.create_or_update(attributes)

returns

  result = model # with all attributes

=end

    def create_or_update(data)
      if data[:id]
        record = find_by(id: data[:id])
        if record
          record.update!(data)
          return record
        end
        record = new(data)
        record.save!
        record
      elsif data[:name]

        # do lookup with == to handle case insensitive databases
        records = if Rails.application.config.db_case_sensitive
                    where('LOWER(name) = LOWER(?)', data[:name])
                  else
                    where(name: data[:name])
                  end
        records.each do |loop_record|
          if loop_record.name == data[:name]
            loop_record.update!(data)
            return loop_record
          end
        end
        record = new(data)
        record.save!
        record
      elsif data[:login]

        # do lookup with == to handle case insensitive databases
        records = if Rails.application.config.db_case_sensitive
                    where('LOWER(login) = LOWER(?)', data[:login])
                  else
                    where(login: data[:login])
                  end
        records.each do |loop_record|
          if loop_record.login.casecmp(data[:login]).zero?
            loop_record.update!(data)
            return loop_record
          end
        end
        record = new(data)
        record.save!
        record
      elsif data[:email]

        # do lookup with == to handle case insensitive databases
        records = if Rails.application.config.db_case_sensitive
                    where('LOWER(email) = LOWER(?)',  data[:email])
                  else
                    where(email: data[:email])
                  end
        records.each do |loop_record|
          if loop_record.email.casecmp(data[:email]).zero?
            loop_record.update!(data)
            return loop_record
          end
        end
        record = new(data)
        record.save!
        record
      elsif data[:locale]

        # do lookup with == to handle case insensitive databases
        records = if Rails.application.config.db_case_sensitive
                    where('LOWER(locale) = LOWER(?)', data[:locale])
                  else
                    where(locale: data[:locale])
                  end
        records.each do |loop_record|
          if loop_record.locale.casecmp(data[:locale]).zero?
            loop_record.update!(data)
            return loop_record
          end
        end
        record = new(data)
        record.save!
        record
      else
        raise ArgumentError, 'Need name, login, email or locale for create_or_update()'
      end
    end
  end
end
