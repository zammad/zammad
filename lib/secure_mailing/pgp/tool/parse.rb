# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module SecureMailing::PGP::Tool::Parse
  extend ActiveSupport::Concern

  include SecureMailing::PGP::Tool::Exec

  PGP_KEY_INFO = Struct.new(:fingerprint, :uids, :created_at, :expires_at, :secret)

  PGP_KEY_INFO_EXPIRES_AT_TIMESTAMP = 6
  PGP_KEY_INFO_CREATED_AT_TIMESTAMP = 5
  PGP_KEY_INFO_UID = 9
  PGP_KEY_INFO_UID_VALIDITY = 1
  PGP_KEY_INFO_UID_INVALID_STATE = %w[i d r n].freeze

  included do # rubocop:disable Metrics/BlockLength

    def info(key)
      result = gpg('show-key', options: %w[--with-colons], stdin: key)

      parse_info(result.stdout)
    end

    private

    def parse_info(data)
      # https://github.com/gpg/gnupg/blob/master/doc/DETAILS
      info = {
        fingerprint: nil,
        uids:        [],
        created_at:  nil,
        expires_at:  nil,
        secret:      false
      }

      data.split("\n").tap do |chunks|
        # We assume all relevant subkeys [SCE] have the same expiration date.
        dates = chunks.find { |chunk| chunk.start_with?(%r{pub|sec}) }
        info[:expires_at]  = expires_at(dates)
        info[:created_at]  = created_at(dates)

        info[:secret] = secret?(chunks)

        fpr = chunks.find { |chunk| chunk.start_with?('fpr') }
        info[:fingerprint] = fingerprint(fpr)

        uids = chunks.select { |chunk| chunk.start_with?('uid') }
        uids = uids.map { |uid| uid(uid) }
        info[:uids] = uids.compact
      end

      PGP_KEY_INFO.new(*info.values)
    end

    def created_at(chunk)
      timestamp = chunk.split(':').fetch(PGP_KEY_INFO_CREATED_AT_TIMESTAMP)
      return nil if timestamp == '0'

      Time.zone.at(timestamp.to_i)
    end

    def expires_at(chunk)
      timestamp = chunk.split(':').fetch(PGP_KEY_INFO_EXPIRES_AT_TIMESTAMP)
      return nil if timestamp.blank? || timestamp == '0'

      Time.zone.at(timestamp.to_i)
    end

    def fingerprint(chunk)
      chunk.split(':').last
    end

    def uid(chunk)
      hunks = chunk.split(':')
      return nil if PGP_KEY_INFO_UID_INVALID_STATE.include?(hunks.fetch(PGP_KEY_INFO_UID_VALIDITY))

      hunks.fetch(PGP_KEY_INFO_UID)
    end

    def secret?(chunks)
      chunks.any? { |chunk| chunk.start_with?('sec') }
    end
  end
end
