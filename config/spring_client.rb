module Spring
  module Client
    class Rails < Command

      DEFAULT_COMMANDS = COMMANDS.dup
      DEFAULT_ALIASES  = ALIASES.dup

      remove_const('COMMANDS')
      remove_const('ALIASES')

      const_set('COMMANDS', DEFAULT_COMMANDS + %w[server])
      const_set('ALIASES', DEFAULT_ALIASES.merge('s' => 'server'))
    end
  end
end
