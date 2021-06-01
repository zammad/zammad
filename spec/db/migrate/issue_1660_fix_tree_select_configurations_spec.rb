# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue1660FixTreeSelectConfigurations, type: :db_migration do

  it 'corrects broken data_option options' do

    # as provided in issue #1775
    expected = [
      {
        'name'     => 'Blaak',
        'value'    => 'Blaak',
        'children' => [
          {
            'name'     => 'BL.-1',
            'value'    => 'Blaak::BL.-1',
            'children' => [
              {
                'name'  => 'BL.-1.3',
                'value' => 'Blaak::BL.-1::BL.-1.3',
              },
              {
                'name'  => 'BL.-1.19',
                'value' => 'Blaak::BL.-1::BL.-1.19',
              }
            ]
          },
          {
            'name'     => 'BL.0',
            'value'    => 'Blaak::BL.0',
            'children' => [
              {
                'name'  => 'BL.00.10a',
                'value' => 'Blaak::BL.0::BL.00.10a',
              },
              {
                'name'  => 'BL.00.7',
                'value' => 'Blaak::BL.0::BL.00.7',
              },
              {
                'name'  => 'BL.01.18',
                'value' => 'Blaak::BL.0::BL.01.18',
              },
              {
                'name'  => 'BL.00.12',
                'value' => 'Blaak::BL.0::BL.00.12',
              },
              {
                'name'  => 'BL.e0.3',
                'value' => 'Blaak::BL.0::BL.e0.3',
              },
            ]
          },
          {
            'name'     => 'BL.1',
            'value'    => 'Blaak::BL.1',
            'children' => [
              {
                'name'  => 'BL.01.i',
                'value' => 'Blaak::BL.1::BL.01.i',
              },
            ]
          },
          {
            'name'     => 'BL.2',
            'value'    => 'Blaak::BL.2',
            'children' => [
              {
                'name'  => 'BL.02.2',
                'value' => 'Blaak::BL.2::BL.02.2',
              },
              {
                'name'  => 'BL.02.4',
                'value' => 'Blaak::BL.2::BL.02.4',
              },
              {
                'name'  => 'BL.02.5',
                'value' => 'Blaak::BL.2::BL.02.5',
              },
              {
                'name'  => 'BL.02.6',
                'value' => 'Blaak::BL.2::BL.02.6',
              },
              {
                'name'  => 'BL.02.7',
                'value' => 'Blaak::BL.2::BL.02.7',
              },
            ]
          },
        ],
      }
    ]

    broken = [
      {
        'name'     => 'Blaak',
        'value'    => 'Blaak',
        'children' => [
          {
            'name'     => 'BL.-1',
            'value'    => 'Blaak::BL.-1',
            'children' => [
              {
                'name'  => 'BL.-1.3',
                'value' => 'Blaak::BL.2::BL.-1.3',
              },
              {
                'name'  => 'BL.-1.19',
                'value' => 'Blaak::BL.2::BL.-1.19',
              }
            ]
          },
          {
            'name'     => 'BL.0',
            'value'    => 'Blaak::BL.0',
            'children' => [
              {
                'name'  => 'BL.00.10a',
                'value' => 'Blaak::BL.2::BL.00.10a',
              },
              {
                'name'  => 'BL.00.7',
                'value' => 'Blaak::BL.2::BL.00.7',
              },
              {
                'name'  => 'BL.01.18',
                'value' => 'Blaak::BL.2::BL.01.18',
              },
              {
                'name'  => 'BL.00.12',
                'value' => 'Blaak::BL.2::BL.00.12',
              },
              {
                'name'  => 'BL.e0.3',
                'value' => 'Blaak::BL.2::BL.e0.3',
              },
            ]
          },
          {
            'name'     => 'BL.1',
            'value'    => 'Blaak::BL.1',
            'children' => [
              {
                'name'  => 'BL.01.i',
                'value' => 'Blaak::BL.2::BL.01.i',
              },
            ]
          },
          {
            'name'     => 'BL.2',
            'value'    => 'Blaak::BL.2',
            'children' => [
              {
                'name'  => 'BL.02.2',
                'value' => 'Blaak::BL.2::BL.02.2',
              },
              {
                'name'  => 'BL.02.4',
                'value' => 'Blaak::BL.2::BL.02.4',
              },
              {
                'name'  => 'BL.02.5',
                'value' => 'Blaak::BL.2::BL.02.5',
              },
              {
                'name'  => 'BL.02.6',
                'value' => 'Blaak::BL.2::BL.02.6',
              },
              {
                'name'  => 'BL.02.7',
                'value' => 'Blaak::BL.2::BL.02.7',
              },
            ]
          },
        ],
      }
    ]

    attribute = create(:object_manager_attribute_tree_select, data_option: { options: broken, null: true, default: '' })

    expect do
      migrate
    end.to change {
      attribute.reload.data_option[:options]
    }

    expect(attribute.data_option[:options]).to eq(expected)
  end

  it 'performs no action for new systems', system_init_done: false do
    migrate do |instance|
      expect(instance).not_to receive(:attributes)
    end
  end

  it 'skips blank data_option options' do
    attribute = create(:object_manager_attribute_tree_select, data_option: { options: [], null: true, default: '' })

    expect do
      migrate
    end.not_to change {
      attribute.reload.data_option[:options]
    }
  end

  it 'does not change correct data_option options' do
    attribute = create(:object_manager_attribute_tree_select)

    expect do
      migrate
    end.not_to change {
      attribute.reload.data_option[:options]
    }
  end
end
