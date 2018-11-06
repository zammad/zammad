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
