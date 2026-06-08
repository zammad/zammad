# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Overcommit::Hook::PreCommit
  # Runs `eslint` against any modified JavaScript files.
  #
  # Protip: if you have a pnpm script set up to run eslint, you can configure
  # this hook to run eslint via your pnpm script by using the `command` option in
  # your .overcommit.yml file. This can be useful if you have some eslint
  # configuration built into your pnpm script that you don't want to repeat
  # somewhere else. Example:
  #
  #   EsLint:
  #     required_executable: 'pnpm'
  #     enabled: true
  #     command: ['pnpm', 'lint:js:eslint:cmd']
  #
  # @see http://eslint.org/
  class Eslint < Base
    def run
      eslint_regex = %r{^(?<file>[^\s](?:\w:)?[^:]+):[^\d]+(?<line>\d+).*?(?<type>Error|Warning)}
      result = execute(command, args: applicable_files)
      output = result.stdout.chomp
      messages = output.split("\n").grep(eslint_regex)

      # return [:fail, result.stderr] if messages.empty? && !result.success?
      return [:fail, result.stdout] if messages.empty? && !result.success?
      return :pass if result.success? && output.empty?

      # example message:
      #   path/to/file.js
      #     1:0  error  Error message ruleName
      extract_messages(messages, eslint_regex, ->(type) { type.downcase.to_sym })
    end
  end
end
