# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module SecureMailing::PGP::Tool::Exec
  extend ActiveSupport::Concern

  include SecureMailing::PGP::Tool::Error::Handler
  include SecureMailing::PGP::Tool::Exec::Agent

  included do # rubocop:disable Metrics/BlockLength
    attr_accessor :gnupg_home

    def with_private_keyring
      dir = Dir.mktmpdir('zammad-gnupg-keyring', Rails.root.join('tmp'))

      begin
        @gnupg_home = dir
        yield(self)
      ensure
        kill_agent
        FileUtils.rm_rf(@gnupg_home)
        @gnupg_home = nil
      end
    end

    def gpg(command, options: [], arguments: [], stdin: nil, passphrase: nil)
      raise __("Use 'with_private_keyring' to create a private keyring or set @gnupg_home before calling gpg.") if !@gnupg_home

      args = %w[--batch --yes --no-tty --verbose --status-fd 2] + options + ["--#{command}"] + arguments
      env = {
        'LC_ALL'    => 'C', # Force use of English
        'GNUPGHOME' => @gnupg_home # Create/use a temporary keyring
      }
      run(args, env, stdin, passphrase)
    end

    private

    def binary_path
      return @which if @which

      if ENV['GPG_PATH'] && File.executable?(ENV['GPG_PATH'])
        @which = ENV['GPG_PATH']
        return @which
      end

      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        gpg = File.join(path, 'gpg')
        if File.executable?(gpg)
          @which = gpg
          return @which
        end
      end

      raise Errno::ENOENT, 'gpg: command not found'
    end

    def run(args, env, stdin, passphrase)
      if passphrase
        passphrase_file = Tempfile.new('passphrase')
        begin
          passphrase_file.write(passphrase)
          passphrase_file.close

          options = [
            '--passphrase-file', passphrase_file.path,
            '--pinentry-mode', 'loopback',
          ]
          args.insert(4, *options)

          stdout, stderr, status = Open3.capture3(env, binary_path, *args, stdin_data: stdin, binmode: true)
        ensure
          passphrase_file.unlink
        end
      else
        stdout, stderr, status = Open3.capture3(env, binary_path, *args, stdin_data: stdin, binmode: true)
      end

      result!([binary_path] + args, env, stdin, { stdout: stdout, stderr: stderr, status: status })
    end
  end
end
