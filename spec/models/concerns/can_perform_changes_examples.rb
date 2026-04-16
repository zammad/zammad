# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'CanPerformChanges', :aggregate_failures do |object_name:, data_privacy_deletion_task: true|
  describe '#perform_changes' do
    let(:object_name_downcase) { object_name.downcase }

    # a `performable` can be a Trigger or a Job
    # we use DuckTyping and expect that a performable
    # implements the following interface
    let(:performable) do
      PERFORMABLE_STRUCT.new(id: 1, perform: perform)
    end

    before do
      stub_const('PERFORMABLE_STRUCT', Struct.new(:id, :perform))
    end

    context 'when data privacy deletion task should be created', if: data_privacy_deletion_task do
      let(:perform) do
        {
          "#{object_name_downcase}.action" => {
            'value' => 'data_privacy_deletion_task',
          }
        }
      end

      it 'does create deletion task' do
        object.perform_changes(performable, 'trigger', object, User.first)

        expect(DataPrivacyTask.last.deletable).to eq(object)
      end
    end

    describe 'Allow placeholders in trigger perform actions for string attributes #4216', db_strategy: :reset do
      let(:custom_attribute_text1) do
        create(:object_manager_attribute_text, name: 'custom_attribute_text1', object_name: object_name)
      end
      let(:custom_attribute_text2) do
        create(:object_manager_attribute_text, name: 'custom_attribute_text2', object_name: object_name)
      end
      let(:object) { create(object_name.downcase.to_sym, custom_attribute_text1: 'testing-example ') }

      let(:perform) do
        {
          "#{object_name_downcase}.custom_attribute_text2" => {
            'value' => "\#{#{object_name_downcase}.custom_attribute_text1}",
          }
        }
      end

      before do
        custom_attribute_text1
        custom_attribute_text2
        ObjectManager::Attribute.migration_execute

        object
      end

      it 'does replace custom fields in trigger' do
        object.perform_changes(performable, 'trigger', object, User.first)
        puts object.reload.custom_attribute_text2
        expect(object.reload.custom_attribute_text2).to eq('testing-example')
      end
    end

    describe 'Allow fields with multiple value support', db_strategy: :reset do
      let(:custom_attribute_multiselect) do
        create(:object_manager_attribute_multiselect, name: 'custom_attribute_multiselect', object_name: object_name)
      end
      let(:object) { create(object_name.downcase.to_sym) }

      let(:perform) do
        {
          "#{object_name_downcase}.custom_attribute_multiselect" => {
            'value' => %w[key_1 key_2],
          }
        }
      end

      before do
        custom_attribute_multiselect
        ObjectManager::Attribute.migration_execute

        object
      end

      it 'does set multi-select field values in trigger' do
        object.perform_changes(performable, 'trigger', object, User.first)
        expect(object.reload.custom_attribute_multiselect).to eq(%w[key_1 key_2])
      end

      context 'when single string is given for multi-select field' do
        let(:perform) do
          {
            "#{object_name_downcase}.custom_attribute_multiselect" => {
              'value' => 'key_1',
            }
          }
        end

        it 'does set multi-select field values in trigger' do
          object.perform_changes(performable, 'trigger', object, User.first)
          expect(object.reload.custom_attribute_multiselect).to eq(%w[key_1])
        end
      end
    end

    # All fields (aside from richtext) are escaped in frontend. No need to escape in database.
    # https://github.com/zammad/zammad/issues/5108
    describe 'Allow special characters', db_strategy: :reset do
      let(:custom_attribute_text1) do
        create(:object_manager_attribute_text, name: 'custom_attribute_text1', object_name: object_name)
      end
      let(:custom_attribute_text2) do
        create(:object_manager_attribute_text, name: 'custom_attribute_text2', object_name: object_name)
      end

      let(:object) { create(object_name.downcase.to_sym, custom_attribute_text2: 'special &&& characters') }

      let(:perform) do
        {
          "#{object_name_downcase}.#{target_field}" => {
            'value' => "\#{#{object_name_downcase}.custom_attribute_text2}",
          }
        }
      end

      before do
        custom_attribute_text1
        custom_attribute_text2
        ObjectManager::Attribute.migration_execute

        object
      end

      context 'when target field is a text field' do
        let(:target_field) { :custom_attribute_text1 }

        it 'does not escape special characters' do
          expect { object.perform_changes(performable, 'trigger') }
            .to change { object.reload.custom_attribute_text1 }
            .to 'special &&& characters'
        end
      end

      context 'when target field is a rich text field' do
        let(:target_field) { :note }

        it 'escapes special characters' do
          expect { object.perform_changes(performable, 'trigger') }
            .to change { object.reload.note }
            .to 'special &amp;&amp;&amp; characters'
        end
      end
    end
  end
end
