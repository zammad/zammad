# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Every option list the cache answers is built again and compared, so that an example which changes something a list is
#   built from fails where the list's key does not know of it.
RSpec.configure do |config|
  config.before do |example|
    next if example.metadata[:form_updater_option_cache_verification] == false

    allow(FormUpdater::OptionCache).to receive(:fetch).and_wrap_original do |original, key, key_source, &block|
      built     = false
      list, key = original.call(key, key_source) do
        built = true

        block.call
      end

      if !built && list != block.call
        raise "FormUpdater::OptionCache answered a list for #{key.inspect} that is not the one built now. Its key lacks something the list is built from."
      end

      [list, key]
    end
  end
end
