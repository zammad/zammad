# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module BulkImportInfo
  def self.enabled?
    Thread.current[:bulk_import]
  end

  def self.enable
    Thread.current[:bulk_import] = true
  end

  def self.disable
    Thread.current[:bulk_import] = false
  end
end
