# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module SecureMailing::PGP::Tool::Data
  extend ActiveSupport::Concern

  include SecureMailing::PGP::Tool::Exec

  included do # rubocop:disable Metrics/BlockLength

    def encrypt(data, recipients)
      options = [
        '--armor',
        '--trust-model', 'always'
      ]
      options += recipients.map { |recipient| ['--recipient', recipient] }.flatten

      gpg('encrypt', options:, stdin: data)
    end

    def decrypt(data, passphrase, skip_verify: false)
      options = [
        '--trust-model', 'always',
      ]
      options << '--skip-verify' if skip_verify

      result = gpg('decrypt', options:, stdin: data, passphrase: passphrase)
      error_algorithm!(result.stderr)

      result
    end

    def sign(data, fingerprint, passphrase)
      options = [
        '--armor',
        '--detach-sign',
        '--trust-model', 'always',
        '--default-key', fingerprint
      ]

      gpg('sign', options:, stdin: data, passphrase: passphrase)
    end

    def verify(data, signature: nil)
      options = [
        '--trust-model', 'always',
      ]

      return verify_detached_signature(options, data, signature) if signature.present?

      gpg('verify', options:, stdin: data)
    end

    private

    def verify_detached_signature(options, data, signature)
      data_file = Tempfile.new('data')
      signature_file = Tempfile.new('signature')
      begin
        data_file.write(data)
        data_file.close

        signature_file.write(signature)
        signature_file.close

        gpg('verify', options:, arguments: [signature_file.path, data_file.path])
      ensure
        data_file.unlink
        signature_file.unlink
      end
    end
  end
end
