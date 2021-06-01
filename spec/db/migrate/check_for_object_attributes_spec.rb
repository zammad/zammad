# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe CheckForObjectAttributes, type: :db_migration do

  it 'performs no action for new systems', system_init_done: false do
    migrate do |instance|
      expect(instance).not_to receive(:attributes)
    end
  end

  context 'with a valid #data_option hash' do

    it 'does not change converted text attribute' do
      attribute = create(:object_manager_attribute_text)

      expect { migrate }
        .not_to change { attribute.reload.data_option }
    end

    it 'does not change select attribute' do
      attribute = create(:object_manager_attribute_select)

      expect { migrate }
        .not_to change { attribute.reload.data_option }
    end

    it 'does not change tree_select attribute' do
      attribute = create(:object_manager_attribute_tree_select)

      expect { migrate }
        .not_to change { attribute.reload.data_option }
    end
  end

  context 'for #data_option key:' do
    context ':options' do

      it 'converts String to Hash' do
        wrong = {
          default:   '',
          options:   '',
          relation:  '',
          type:      'text',
          maxlength: 255,
          null:      true
        }

        attribute = create(:object_manager_attribute_text, data_option: wrong)
        migrate
        attribute.reload

        expect(attribute[:data_option][:options]).to be_a(Hash)
        expect(attribute[:data_option][:options]).to be_blank
      end
    end

    context ':relation' do

      it 'ensures an empty String' do
        wrong = {
          default:   '',
          options:   {},
          type:      'text',
          maxlength: 255,
          null:      true
        }

        attribute = create(:object_manager_attribute_text, data_option: wrong)
        migrate
        attribute.reload

        expect(attribute[:data_option][:relation]).to be_a(String)
      end

      it 'converts Hash to String' do
        wrong = {
          default:   '',
          options:   {},
          relation:  {},
          type:      'text',
          maxlength: 255,
          null:      true
        }

        attribute = create(:object_manager_attribute_text, data_option: wrong)
        migrate
        attribute.reload

        expect(attribute[:data_option][:relation]).to be_a(String)
        expect(attribute[:data_option][:relation]).to be_blank
      end
    end

    # see https://github.com/zammad/zammad/issues/2159
    context ':null' do

      it 'does not fail on missing values' do
        wrong = {
          default:   '',
          options:   '',      # <- this is not the attribute under test,
          relation:  '',      #    but it must be invalid
          type:      'text',  #    to trigger a #save in the migration.
          maxlength: 255,
        }
        create(:object_manager_attribute_text)
          .update_columns(data_option: wrong)

        expect { migrate }.not_to raise_error
      end
    end
  end

  # regression test for issue #2318 - Upgrade to Zammad 2.7 was not possible (migration 20180220171219 CheckForObjectAttributes failed)
  context 'for interger attributes' do
    it 'missing :min and :max' do
      attribute = create(:object_manager_attribute_integer)
      attribute.update_columns(data_option: {})

      expect { migrate }.not_to raise_error

      attribute.reload

      expect(attribute[:data_option][:min]).to be_a(Integer)
      expect(attribute[:data_option][:max]).to be_a(Integer)
    end
  end
end
