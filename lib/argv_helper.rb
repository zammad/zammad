# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# Unfortunately, Rails clears ARGV when executing commands, so copy it early at startup
#   for later usage.
# See also https://github.com/rails/rails/commit/8ec7a2b7aaa31527686b05e0640d125299933782.
module ArgvHelper
  ORIGINAL_ARGV = ARGV.dup.freeze

  def self.argv
    ORIGINAL_ARGV
  end
end
