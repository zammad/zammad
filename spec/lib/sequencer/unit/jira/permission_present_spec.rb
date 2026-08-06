# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Jira::PermissionPresent, sequencer: :unit do

  context 'when checking the permission to browse the Jira project' do

    let(:params) do
      {
        dry_run:    false,
        import_job: instance_double(ImportJob),
      }
    end

    it 'is present when BROWSE_PROJECTS is granted' do
      allow(described_class).to receive(:get_json).with(any_args).and_return(
        'permissions' => { 'BROWSE_PROJECTS' => { 'havePermission' => true } }
      )
      expect(process(params)).to eq({ permission_present: true })
    end

    it 'is absent when BROWSE_PROJECTS is denied' do
      allow(described_class).to receive(:get_json).with(any_args).and_return(
        'permissions' => { 'BROWSE_PROJECTS' => { 'havePermission' => false } }
      )
      expect(process(params)).to eq({ permission_present: false })
    end

    it 'is absent when the request fails' do
      allow(described_class).to receive(:get_json).with(any_args).and_return(nil)
      expect(process(params)).to eq({ permission_present: false })
    end
  end
end
