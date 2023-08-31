# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module SecureMailing::PGP::Tool::Parse
  extend ActiveSupport::Concern

  include SecureMailing::PGP::Tool::Exec

  PGP_KEY_INFO = Struct.new(:fingerprint, :uids, :created_at, :expires_at, :secret)

  PGP_KEY_INFO_EXPIRES_AT_TIMESTAMP = 6
  PGP_KEY_INFO_CREATED_AT_TIMESTAMP = 5
  PGP_KEY_INFO_UID = 9

  included do # rubocop:disable Metrics/BlockLength

    def info(key)
      result = gpg('show-key', options: %w[--with-colons], stdin: key)

      parse_info(result.stdout)
    end

    private

    def parse_info(data) # rubocop:disable Metrics/AbcSize
      info = {
        fingerprint: nil,
        uids:        [],
        created_at:  nil,
        expires_at:  nil,
        secret:      false
      }

      data.split("\n").each_with_index do |chunk, idx|
        # We assume all relevant subkeys [SCE] have the same expiration date.
        info[:expires_at]  = determine_expires_at(chunk) if idx.zero?
        info[:created_at]  = determine_created_at(chunk) if idx.zero?
        info[:secret]      = determine_secret(chunk) if idx.zero?
        info[:fingerprint] = determine_fingerprint(chunk) if idx == 1

        next if !chunk.start_with?('uid')

        info[:uids] << determine_uid(chunk)
      end

      PGP_KEY_INFO.new(*info.values)
    end

    def determine_expires_at(chunk)
      timestamp = chunk.split(':').fetch(PGP_KEY_INFO_EXPIRES_AT_TIMESTAMP)
      return nil if timestamp.blank? || timestamp == '0'

      Time.zone.at(timestamp.to_i)
    end

    def determine_created_at(chunk)
      timestamp = chunk.split(':').fetch(PGP_KEY_INFO_CREATED_AT_TIMESTAMP)
      return nil if timestamp == '0'

      Time.zone.at(timestamp.to_i)
    end

    def determine_fingerprint(chunk)
      chunk.split(':').last
    end

    def determine_secret(chunk)
      chunk.start_with?('sec')
    end

    def determine_uid(chunk)
      chunk.split(':').fetch(PGP_KEY_INFO_UID)
    end
  end
end
