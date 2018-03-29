require 'rails_helper'

RSpec.describe CheckForObjectAttributes, type: :db_migration do

  it 'performs no action for new systems' do
    system_init_done(false)

    migrate do |instance|
      expect(instance).not_to receive(:attributes)
    end
  end

  context 'valid [:data_option]' do

    it 'does not change converted text attribute' do
      system_init_done

      attribute = create(:object_manager_attribute_text)

      expect do
        migrate
      end.not_to change {
        attribute.reload.data_option
      }
    end

    it 'does not change select attribute' do
      system_init_done

      attribute = create(:object_manager_attribute_select)

      expect do
        migrate
      end.not_to change {
        attribute.reload.data_option
      }
    end

    it 'does not change tree_select attribute' do
      system_init_done

      attribute = create(:object_manager_attribute_tree_select)

      expect do
        migrate
      end.not_to change {
        attribute.reload.data_option
      }
    end
  end

  context '[:data_option]' do

    it 'ensures an empty Hash' do
      system_init_done

      attribute = create(:object_manager_attribute_text, data_option: nil)
      migrate
      attribute.reload

      expect(attribute[:data_option]).to be_a(Hash)
    end
  end

  context '[:data_option][:options]' do

    it 'ensures an empty Hash' do
      system_init_done

      attribute = create(:object_manager_attribute_text, data_option: {})
      migrate
      attribute.reload

      expect(attribute[:data_option][:options]).to be_a(Hash)
    end

    it 'converts String to Hash' do
      system_init_done

      wrong = {
        default:  '',
        options:  '',
        relation: '',
        null:     true
      }

      attribute = create(:object_manager_attribute_text, data_option: wrong)
      migrate
      attribute.reload

      expect(attribute[:data_option][:options]).to be_a(Hash)
      expect(attribute[:data_option][:options]).to be_blank
    end
  end

  context '[:data_option][:relation]' do

    it 'ensures an empty String' do
      system_init_done

      wrong = {
        default: '',
        options: {},
        null:    true
      }

      attribute = create(:object_manager_attribute_text, data_option: wrong)
      migrate
      attribute.reload

      expect(attribute[:data_option][:relation]).to be_a(String)
    end

    it 'converts Hash to String' do
      system_init_done

      wrong = {
        default:  '',
        options:  {},
        relation: {},
        null:     true
      }

      attribute = create(:object_manager_attribute_text, data_option: wrong)
      migrate
      attribute.reload

      expect(attribute[:data_option][:relation]).to be_a(String)
      expect(attribute[:data_option][:relation]).to be_blank
    end
  end
end
