# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
      identifier = [:id, :name, :login, :email, %i[source locale]].map { |a| data.slice(*a) }.find(&:any?) || {}

      case_sensitive_find_by(**identifier) || create(data)
    end

=begin

create or update model (check exists based on id, name, login, email or locale)

  result = Model.create_or_update(attributes)

returns

  result = model # with all attributes

=end

    def create_or_update(data)
      attr = (data.keys & %i[id name login email locale]).first

      raise ArgumentError, 'Need name, login, email or locale for create_or_update()' if attr.nil?

      record = case_sensitive_find_by(data.slice(attr))
      record.nil? ? create(data) : record.tap { |r| r.update(data) }
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

Model.create_or_update with ref lookups

  result = Model.create_or_update(attributes)

returns

  result = model # with all attributes

=end

    def create_or_update_with_ref(data)
      data = association_name_to_id_convert(data)
      create_or_update(data)
    end

    def case_sensitive_find_by(**attrs)
      return nil if attrs.empty?
      return find_by(**attrs) if Rails.application.config.db_case_sensitive || attrs.values.none?(String)

      where(**attrs).find { |record| record[attrs.keys.first] == attrs.values.first }
    end
  end

  included do
    private_class_method :case_sensitive_find_by
  end
end
