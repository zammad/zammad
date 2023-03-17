# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Exchange::FolderContact::HttpLog < Sequencer::Unit::Import::Common::Model::HttpLog

  private

  def facility
    'EWS'
  end
end
