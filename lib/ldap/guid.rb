# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Ldap

  # Class for handling LDAP GUIDs.
  # strongly inspired by
  # https://gist.github.com/astockwell/359c950fbc650c339eea
  # Big thanks to @astockwell
  class Guid

    # Checks if the given string is a valid GUID.
    #
    # @param string [String] The string that should be checked for valid GUID format.
    #
    # @example
    #  Ldap::Guid.valid?('f742b361-32c6-4a92-baaa-eaae7df657ee')
    #  #=> true
    #
    # @return [Boolean]
    def self.valid?(string)
      string.match?(%r{\w{8}-\w{4}-\w{4}-\w{4}-\w+})
    end

    # Convers a given GUID string into the HEX equivalent.
    #
    # @param string [String] The GUID string that should converted into HEX.
    #
    # @example
    #  Ldap::Guid.hex('f742b361-32c6-4a92-baaa-eaae7df657ee')
    #  #=> "a\xB3B\xF7\xC62\x92J\xBA\xAA\xEA\xAE}\xF6W\xEE".b
    #
    # @return [String] The HEX equivalent of the given GUID string.
    def self.hex(string)
      new(string).hex
    end

    # Convers a given HEX string into the GUID equivalent.
    #
    # @param string [String] The HEX string that should converted into a GUID.
    #
    # @example
    #  Ldap::Guid.string("a\xB3B\xF7\xC62\x92J\xBA\xAA\xEA\xAE}\xF6W\xEE".b)
    #  #=> 'f742b361-32c6-4a92-baaa-eaae7df657ee'
    #
    # @return [String] The GUID equivalent of the given HEX string.
    def self.string(hex)
      new(hex).string
    end

    # Initializes an instance for the LDAP::Guid class to convert from/to HEX and GUID strings.
    #
    # @param string [String] The HEX or GUID string that should converted.
    #
    # @example
    #  guid = Ldap::Guid.new('f742b361-32c6-4a92-baaa-eaae7df657ee')
    #
    # @return [nil]
    def initialize(guid)
      @guid = guid
    end

    # Convers the GUID string into the HEX equivalent.
    #
    # @example
    #  guid.hex
    #  #=> "a\xB3B\xF7\xC62\x92J\xBA\xAA\xEA\xAE}\xF6W\xEE".b
    #
    # @return [String] The HEX equivalent of the GUID string.
    def hex
      [oracle_raw16(guid)].pack('H*')
    end

    # Convers the HEX string into the GUID equivalent.
    #
    # @example
    #  guid.string
    #  #=> 'f742b361-32c6-4a92-baaa-eaae7df657ee'
    #
    # @return [String] The GUID equivalent of the HEX string.
    def string
      oracle_raw16(guid.unpack1('H*'), dashify: true)
    end

    private

    attr_reader :guid

    def oracle_raw16(string, dashify: false)
      # remove dashes
      string.delete!('-')

      # split every two chars
      parts = string.scan(%r{.{1,2}})

      # re-order according to oracle format index and join
      oracle_format_indices = [3, 2, 1, 0, 5, 4, 7, 6, 8, 9, 10, 11, 12, 13, 14, 15]
      result                = oracle_format_indices.map { |index| parts[index] }.join

      # add dashes if requested
      return result if !dashify

      [
        result[0..7],
        result[8..11],
        result[12..15],
        result[16..19],
        result[20..result.size]
      ].join('-')
    end
  end
end
