# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ApplicationModel::CanQueryCaseInsensitiveWhereOrSql
  extend ActiveSupport::Concern

  included do

    # Builds a case-insensitive WHERE ... OR ... SQL query.
    #
    # @see .or_cis
    #
    # @example
    #  Organization.where_or_cis(%i[name note], "%zammad%").to_sql
    #  #=> "SELECT `organizations`.* FROM `organizations` WHERE (`organizations`.`name` LIKE '%zammad%' OR `organizations`.`note` LIKE '%zammad%')"
    #
    # @return [ActiveRecord::Relation] the ActiveRecord relation that can be combined or executed
    scope :where_or_cis, ->(*args) { where(or_cis(*args)) }
  end

  # methods defined here are going to extend the class, not the instance of it
  class_methods do

    # Builds a case-insensitive OR SQL grouping. This comes in handy for join queries.
    # For direct WHERE queries prefer .where_or_cis scope.
    #
    # @param [Array] attributes the attributes that should get queried case-insensitive. Strings or Arel attributes
    # @param [String] query the SQL query that should be used for each given attribute.
    #
    # @example
    #  Organization.joins(:users).where(User.or_cis(%i[firstname lastname email], "%#{query}%"))
    #
    # @return [Arel::Nodes::Grouping] can be passed to ActiveRecord queries
    def or_cis(attributes, query)
      # use Arel to create an Array of case-insensitive
      # LIKE queries based on the current DB adapter
      cis_matches = attributes
                    .map do |attribute|
                      next attribute if attribute.is_a? Arel::Attributes::Attribute

                      arel_table[attribute]

                    end.map { |attribute| attribute.matches(query) }

      # return the by OR joined Arel queries
      cis_matches.inject(:or)
    end
  end
end
