# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
      signature_file = Tempfile.new('signature')
      begin
        signature_file.write(signature)
        signature_file.close

        if signature.to_s.include?('-----BEGIN PGP SIGNATURE-----')
          # Standard RFC 3156 detached signature: GPG verifies against the supplied data.
          verify_with_data_file(options, data, signature_file.path)
        elsif signature.to_s.include?('-----BEGIN PGP MESSAGE-----')
          # Non-standard opaque (inline) signature: GPG verifies the content embedded
          # inside the blob, not the supplied data. We must also check that the embedded
          # content matches the displayed body to prevent signature substitution attacks
          # where an attacker reuses an old opaque signed message for arbitrary content.
          verify_opaque_signature(options, data, signature_file.path)
        else
          raise __('Invalid signature format: expected a PGP signature')
        end
      ensure
        signature_file.unlink
      end
    end

    def verify_opaque_signature(options, data, signature_file_path)
      result = gpg('verify', options:, arguments: [signature_file_path])

      extraction = gpg('decrypt', options: options + ['--skip-verify'], arguments: [signature_file_path])

      return result if extraction.stdout.strip == data.strip

      raise __('PGP signature does not cover the displayed message body')
    end

    def verify_with_data_file(options, data, signature_file_path)
      data_file = Tempfile.new('data')
      begin
        data_file.write(data)
        data_file.close
        gpg('verify', options:, arguments: [signature_file_path, data_file.path])
      ensure
        data_file.unlink
      end
    end
  end
end
