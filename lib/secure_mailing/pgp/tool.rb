# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SecureMailing::PGP::Tool
  include SecureMailing::PGP::Tool::Key
  include SecureMailing::PGP::Tool::Data
  include SecureMailing::PGP::Tool::Parse

  def self.version
    stdout, stderr, status = Open3.capture3({ 'LC_ALL' => 'C' }, 'gpg', '--version')
    raise Errno::EHWPOISON, stderr if !status.success?

    stdout.split("\n").first.split.last
  end
end
