# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module SecureMailing::PGP::Tool::Error::Handler
  extend ActiveSupport::Concern

  PGP_CALL_RESULT = Struct.new(:stdout, :stderr, :status)

  included do # rubocop:disable Metrics/BlockLength
    private

    def log(cmd, env, stdin, result)
      log_level = result[:status].success? ? :debug : :error

      Rails.logger.send(log_level) { "PGP: Version: #{SecureMailing::PGP::Tool.version}" }
      Rails.logger.send(log_level) { "PGP: Exec: #{cmd.join(' ')}" }
      Rails.logger.send(log_level) { "PGP: Env: #{env}" }
      Rails.logger.send(log_level) { "PGP: Stderr: #{result[:stderr]}" }
      Rails.logger.send(log_level) { "PGP: Status: #{result[:status]}" }

      return if !Rails.logger.debug?

      Rails.logger.debug { "PGP: Stdin: #{stdin}" } if stdin
      Rails.logger.debug { "PGP: Stdout: #{result[:stdout]}" }
    end

    def error!(stderr)
      stderr.each_line do |line|
        next if !line.start_with?('[GNUPG:]')
        next if !(exception = SecureMailing::PGP::Tool::Error.exception(line.split.second))

        raise exception, nil, [sanitize_stderr(stderr)]
      end

      raise SecureMailing::PGP::Tool::Error::UnknownError, nil, [sanitize_stderr(stderr)]
    end

    def error_export!(stderr, secret)
      exception = secret ? 'NoSecretKey' : 'NoPublicKey'

      raise "SecureMailing::PGP::Tool::Error::#{exception}".constantize, nil, [stderr]
    end

    def error_passphrase!(stderr)
      ['no passphrase', 'bad passphrase'].each do |phrase|
        next if stderr.downcase.exclude?(phrase)

        exception = "SecureMailing::PGP::Tool::Error::#{phrase.tr(' ', '_').camelize}".constantize
        raise exception, nil, [stderr]
      end
    end

    def error_algorithm!(stderr)
      raise SecureMailing::PGP::Tool::Error::UnknownError, __('This PGP email was encrypted with a potentially unknown encryption algorithm.'), [stderr] if stderr.downcase.exclude?('encrypted data')
    end

    def result!(cmd, env, stdin, result)
      log(cmd, env, stdin, result)

      error_passphrase!(sanitize_stderr(result[:stderr])) if result[:stderr].present?
      return PGP_CALL_RESULT.new(result[:stdout], sanitize_stderr(result[:stderr]), result[:status]) if result[:status].success?

      error!(result[:stderr])
    end

    def sanitize_stderr(string)
      string.split("\n").reject { |chunk| chunk.start_with?('[GNUPG:]') }.join("\n")
    end
  end
end
