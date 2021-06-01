# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Common::Model::ResetPrimaryKeySequence, sequencer: :unit do

  it 'calls DbHelper.import_post for given model_class' do

    model_class = ::User

    expect(DbHelper).to receive(:import_post).with(model_class.table_name)

    process(model_class: model_class)
  end
end
