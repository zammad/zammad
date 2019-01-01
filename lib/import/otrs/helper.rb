module Import
  module OTRS
    module Helper
      extend self

      private

      def from_mapping(record)
        result = {}
        # use the mapping of the class in which
        # this module gets extended
        self.class::MAPPING.each do |key_sym, value|
          key = key_sym.to_s
          next if !record.key?(key)

          result[value] = record[key]
        end
        result
      end

      def active?(record)
        case record['ValidID'].to_s
        when '3'
          false
        when '2'
          false
        when '1'
          true
        when '0'
          false
        else
          true
        end
      end
    end
  end
end
