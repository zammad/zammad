require 'rails_helper'

RSpec.describe Import::ModelResource do

  before do
    module Import
      class Test < Import::Base
        class Group < Import::ModelResource
          def source
            'RSpec-Test'
          end
        end
      end
    end
  end

  after do
    Import::Test.send(:remove_const, :Group)
  end

  let(:group_data) { attributes_for(:group).merge(id: 1337) }

  it 'creates model Objects by class name' do
    expect {
      Import::Test::Group.new(group_data)
    }.to change { Group.count }.by(1)
  end

  it 'updates model Objects by class name' do

    expect do
      Import::Test::Group.new(group_data)
    end
      .to change {
            Group.count
          }.by(1)

    expect do
      Import::Test::Group.new(group_data.merge(note: 'Updated'))
    end
      .to change {
            Group.count
          }.by(0)
      .and change {
             Group.last.note
           }
  end
end
