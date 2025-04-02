# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Service
  class SystemAssets
    SendableAsset = Struct.new(:content, :filename, :type, keyword_init: true)

    def self.backend(identifier)
      "#{name}::#{identifier.camelize}".safe_constantize
    end
  end
end
