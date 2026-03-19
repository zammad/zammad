# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module SecureMailing::PGP::Tool::Exec::Agent
  extend ActiveSupport::Concern

  included do
    def kill_agent
      socket = agent_socket
      gpgconf(%w[--kill gpg-agent])

      # Wait for the gpg-agent to shut down and remove its socket file.
      time_slept = 0
      while File.exist?(socket)
        if (time_slept += 0.1) > 10
          # Log a warning and force to kill remaining agents
          Rails.logger.warn("PGP: Agent socket still exists. Killing leftover agents.")
          system("pkill -9 -u #{Process.uid} gpg-agent")
          break
        end
        sleep 0.1
      end
    end

    private

    def agent_socket
      gpgconf(%w[--list-dir agent-socket]).strip
    end

    def gpgconf(cmdline)
      raise __("Use 'with_private_keyring' to create a private keyring or set @gnupg_home before calling gpg.") if !@gnupg_home

      bin = "#{File.dirname(binary_path)}/gpgconf"
      cmd = [bin] + cmdline
      env = { 'GNUPGHOME' => @gnupg_home }
      stdout, stderr, status = Open3.capture3(env, *cmd, binmode: true)
      Rails.logger.error { "PGP: #{cmd}: #{stderr}" } if !status.success?

      stdout
    end

  end
end
