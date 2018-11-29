# encoding: UTF-8

module Mysql2
  class Error < StandardError
    ENCODE_OPTS = {
      :undef => :replace,
      :invalid => :replace,
      :replace => '?'.freeze,
    }.freeze

    attr_reader :error_number, :sql_state

    # Mysql gem compatibility
    alias_method :errno, :error_number
    alias_method :error, :message

    def initialize(msg)
      @server_version ||= nil

      super(clean_message(msg))
    end

    def self.new_with_args(msg, server_version, error_number, sql_state)
      err = allocate
      err.instance_variable_set('@server_version', server_version)
      err.instance_variable_set('@error_number', error_number)
      err.instance_variable_set('@sql_state', sql_state.respond_to?(:encode) ? sql_state.encode(ENCODE_OPTS) : sql_state)
      err.send(:initialize, msg)
      err
    end

    private

    # In MySQL 5.5+ error messages are always constructed server-side as UTF-8
    # then returned in the encoding set by the `character_set_results` system
    # variable.
    #
    # See http://dev.mysql.com/doc/refman/5.5/en/charset-errors.html for
    # more context.
    #
    # Before MySQL 5.5 error message template strings are in whatever encoding
    # is associated with the error message language.
    # See http://dev.mysql.com/doc/refman/5.1/en/error-message-language.html
    # for more information.
    #
    # The issue is that the user-data inserted in the message could potentially
    # be in any encoding MySQL supports and is insert into the latin1, euckr or
    # koi8r string raw. Meaning there's a high probability the string will be
    # corrupt encoding-wise.
    #
    # See http://dev.mysql.com/doc/refman/5.1/en/charset-errors.html for
    # more information.
    #
    # So in an attempt to make sure the error message string is always in a valid
    # encoding, we'll assume UTF-8 and clean the string of anything that's not a
    # valid UTF-8 character.
    #
    # Except for if we're on 1.8, where we'll do nothing ;)
    #
    # Returns a valid UTF-8 string in Ruby 1.9+, the original string on Ruby 1.8
    def clean_message(message)
      return message unless message.respond_to?(:encode)

      if @server_version && @server_version > 50500
        message.encode(ENCODE_OPTS)
      else
        message.encode(Encoding::UTF_8, ENCODE_OPTS)
      end
    end
  end
end
