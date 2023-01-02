# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Exchange::FolderContact::Statistics::Diff < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Model::Statistics::Mixin::ActionDiff

  uses :ews_folder_name

  def process
    state.provide(:statistics_diff) do
      # build structure for a general diff
      # and a folder specific sub structure
      diff.merge(
        folders: {
          ews_folder_name => diff
        }
      )
    end
  end

  private

  def actions
    %i[created updated unchanged skipped failed]
  end
end
