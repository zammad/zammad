# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Exchange::FolderContacts::FolderIds < Sequencer::Unit::Common::Provider::Fallback

  provides :ews_folder_ids

  private

  def ews_folder_ids
    ::Import::Exchange.config[:folders]
  end
end
