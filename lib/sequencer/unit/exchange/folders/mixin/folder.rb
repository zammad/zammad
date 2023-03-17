# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Sequencer::Unit::Exchange::Folders::Mixin::Folder

  def self.included(base)
    base.uses :ews_connection
  end

  private

  def ews_folder
    @ews_folder ||= ::Import::Exchange::Folder.new(ews_connection)
  end
end
