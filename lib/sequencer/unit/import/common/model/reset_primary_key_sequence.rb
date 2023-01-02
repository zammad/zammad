# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::Model::ResetPrimaryKeySequence < Sequencer::Unit::Base
  extend Forwardable

  uses :model_class

  delegate table_name: :model_class

  def process
    DbHelper.import_post(table_name)
  end
end
