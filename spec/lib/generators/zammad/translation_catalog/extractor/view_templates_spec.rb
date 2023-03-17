# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Zammad::TranslationCatalog::Extractor::ViewTemplates do
  subject(:extractor_module) { described_class.new(options: {}) }

  let(:filename) { 'myfile' }
  let(:result_strings) do
    extractor_module.extract_from_string(string, filename)
    extractor_module.extracted_strings.keys.sort
  end

  context 'with strings to be found' do
    let(:string) do
      <<~'TEMPLATE'
        New Ticket (#{ticket.title})

        <div>Hi #{recipient.firstname},</div>
        <br>
        <div>A new ticket (#{ticket.title}) has been created by "<b>#{current_user.longname}</b>".</div>
      TEMPLATE
    end

    it 'finds the correct strings' do
      expect(result_strings).to eq([string])
    end
  end
end
