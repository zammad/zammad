# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'active_record/relation/calculations'

module ActiveRecord
  module Calculations
    # plucks attributes and create a hash instead of returning an array
    #
    # @see ActiveRecord::Calculations#pluck
    #
    # @param [<String, Symbol, SqlLiteral>] attributes to fetch
    #
    # @return [<Hash<String=>Any>]
    #
    # @example
    #   Ticket.all.pluck_as_hash(:title) # [{title: 'A'}, {title: 'B'}]
    #   Ticket.all.pluck_as_hash(:title, :owner_id) # [{title: 'A', owner_id: 1}, {title: 'B', owner_id: 2}]
    def pluck_as_hash(*column_names)
      column_names.flatten! # flatten args in case array was given

      klass.disallow_raw_sql!(column_names) # validate parameters as in #pluck

      pluck(*arel_columns(column_names))
        .map { |elem| pluck_as_hash_map(column_names, elem) }
    end

    private

    def pluck_as_hash_map(keys, values)
      if keys.one?
        {
          keys.first => values
        }
      else
        keys.zip(values).to_h
      end
    end
  end
end

module Enumerable
  def pluck_as_hash(*column_names)
    column_names.flatten! # flatten args in case array was given

    pluck(*column_names)
      .map { |elem| pluck_as_hash_map(column_names, elem) }
  end

  private

  def pluck_as_hash_map(keys, values)
    if keys.one?
      {
        keys.first => values
      }
    else
      keys.zip(values).to_h
    end
  end
end
