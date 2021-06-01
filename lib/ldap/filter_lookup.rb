# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Ldap
  module FilterLookup

    # Returns the first of a list of filters which has entries.
    #
    # @example
    #  instance.lookup_filter(['filter1', 'filter2'])
    #  #=> 'filter2'
    #
    # @return [String, nil] The first filter with entries or nil.
    def lookup_filter(possible_filters)
      result = nil
      possible_filters.each do |possible_filter|
        next if !@ldap.entries?(possible_filter)

        result = possible_filter
        break
      end
      result
    end

  end
end
