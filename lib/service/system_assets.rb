# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Service
  class SystemAssets
    SendableAsset = Struct.new(:content, :filename, :type)

    def self.backend(identifier)
      "#{name}::#{identifier.camelize}".safe_constantize
    end
  end
end
