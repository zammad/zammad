# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'core workflow' do
  let(:field_name) { SecureRandom.hex(10) }
  let(:screens) do
    {
      create_middle: {
        '-all-' => {
          shown:    true,
          required: false,
        },
      },
      create:        {
        '-all-' => {
          shown:    true,
          required: false,
        },
      },
      edit:          {
        '-all-' => {
          shown:    true,
          required: false,
        },
      },
    }
  end

  describe 'modify input attribute', authenticated_as: :authenticate, db_strategy: :reset do
    def authenticate
      create(:object_manager_attribute_text, object_name: object_name, name: field_name, display: field_name, screens: screens)
      ObjectManager::Attribute.migration_execute
      true
    end

    describe 'action - show' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'show',
                   show:     'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector("input[name='#{field_name}']")
      end
    end

    describe 'action - hide' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'hide',
                   hide:     'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector(".form-group[data-attribute-name='#{field_name}'].is-hidden", visible: :hidden)
      end
    end

    describe 'action - remove' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'remove',
                   remove:   'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector(".form-group[data-attribute-name='#{field_name}'].is-removed", visible: :hidden)
      end
    end

    describe 'action - set_optional' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:     'set_optional',
                   set_optional: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page.find("div[data-attribute-name='#{field_name}'] div.formGroup-label label")).to have_no_text('*')
      end
    end

    describe 'action - set_mandatory' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:      'set_mandatory',
                   set_mandatory: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page.find("div[data-attribute-name='#{field_name}'] div.formGroup-label label")).to have_text('*')
      end
    end

    describe 'action - unset_readonly' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:       'unset_readonly',
                   unset_readonly: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_no_selector("div[data-attribute-name='#{field_name}'].is-readonly")
      end
    end

    describe 'action - set_readonly' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:     'set_readonly',
                   set_readonly: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector("div[data-attribute-name='#{field_name}'].is-readonly")
      end
    end

    describe 'action - fill_in' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'fill_in',
                   fill_in:  '4cddb2twza'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_field(field_name, with: '4cddb2twza')
      end
    end

    describe 'action - fill_in_empty' do
      describe 'with match' do
        before do
          create(:core_workflow,
                 object:  object_name,
                 perform: {
                   "#{object_name.downcase}.#{field_name}": {
                     operator:      'fill_in_empty',
                     fill_in_empty: '9999'
                   },
                 })
        end

        it 'does perform' do
          before_it.call
          expect(page).to have_field(field_name, with: '9999')
        end
      end

      describe 'without match' do
        before do
          create(:core_workflow,
                 object:  object_name,
                 perform: {
                   "#{object_name.downcase}.#{field_name}": {
                     operator: 'fill_in',
                     fill_in:  '4cddb2twza'
                   },
                 })
          create(:core_workflow,
                 object:  object_name,
                 perform: {
                   "#{object_name.downcase}.#{field_name}": {
                     operator:      'fill_in_empty',
                     fill_in_empty: '9999'
                   },
                 })
        end

        it 'does perform' do
          before_it.call
          expect(page).to have_no_field(field_name, with: '9999')
        end
      end
    end
  end

  describe 'modify textarea attribute', authenticated_as: :authenticate, db_strategy: :reset do
    def authenticate
      create(:object_manager_attribute_textarea, object_name: object_name, name: field_name, display: field_name, screens: screens)
      ObjectManager::Attribute.migration_execute
      true
    end

    describe 'action - show' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'show',
                   show:     'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector("textarea[name='#{field_name}']")
      end
    end

    describe 'action - hide' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'hide',
                   hide:     'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector(".form-group[data-attribute-name='#{field_name}'].is-hidden", visible: :hidden)
      end
    end

    describe 'action - remove' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'remove',
                   remove:   'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector(".form-group[data-attribute-name='#{field_name}'].is-removed", visible: :hidden)
      end
    end

    describe 'action - set_optional' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:     'set_optional',
                   set_optional: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page.find("div[data-attribute-name='#{field_name}'] div.formGroup-label label")).to have_no_text('*')
      end
    end

    describe 'action - set_mandatory' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:      'set_mandatory',
                   set_mandatory: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page.find("div[data-attribute-name='#{field_name}'] div.formGroup-label label")).to have_text('*')
      end
    end

    describe 'action - unset_readonly' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:       'unset_readonly',
                   unset_readonly: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_no_selector("div[data-attribute-name='#{field_name}'].is-readonly")
      end
    end

    describe 'action - set_readonly' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:     'set_readonly',
                   set_readonly: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector("div[data-attribute-name='#{field_name}'].is-readonly")
      end
    end

    describe 'action - fill_in' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'fill_in',
                   fill_in:  '4cddb2twza'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_field(field_name, with: '4cddb2twza')
      end
    end

    describe 'action - fill_in_empty' do
      describe 'with match' do
        before do
          create(:core_workflow,
                 object:  object_name,
                 perform: {
                   "#{object_name.downcase}.#{field_name}": {
                     operator:      'fill_in_empty',
                     fill_in_empty: '9999'
                   },
                 })
        end

        it 'does perform' do
          before_it.call
          expect(page).to have_field(field_name, with: '9999')
        end
      end

      describe 'without match' do
        before do
          create(:core_workflow,
                 object:  object_name,
                 perform: {
                   "#{object_name.downcase}.#{field_name}": {
                     operator: 'fill_in',
                     fill_in:  '4cddb2twza'
                   },
                 })
          create(:core_workflow,
                 object:  object_name,
                 perform: {
                   "#{object_name.downcase}.#{field_name}": {
                     operator:      'fill_in_empty',
                     fill_in_empty: '9999'
                   },
                 })
        end

        it 'does perform' do
          before_it.call
          expect(page).to have_no_field(field_name, with: '9999')
        end
      end
    end
  end

  describe 'modify select attribute', authenticated_as: :authenticate, db_strategy: :reset do
    def authenticate
      create(:object_manager_attribute_select, object_name: object_name, name: field_name, display: field_name, screens: screens)
      ObjectManager::Attribute.migration_execute
      true
    end

    describe 'action - show' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'show',
                   show:     'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector("select[name='#{field_name}']")
      end
    end

    describe 'action - hide' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'hide',
                   hide:     'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector(".form-group[data-attribute-name='#{field_name}'].is-hidden", visible: :hidden)
      end
    end

    describe 'action - remove' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'remove',
                   remove:   'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector(".form-group[data-attribute-name='#{field_name}'].is-removed", visible: :hidden)
      end
    end

    describe 'action - set_optional' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:     'set_optional',
                   set_optional: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page.find("div[data-attribute-name='#{field_name}'] div.formGroup-label label")).to have_no_text('*')
      end
    end

    describe 'action - set_mandatory' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:      'set_mandatory',
                   set_mandatory: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page.find("div[data-attribute-name='#{field_name}'] div.formGroup-label label")).to have_text('*')
      end
    end

    describe 'action - unset_readonly' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:       'unset_readonly',
                   unset_readonly: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_no_selector("div[data-attribute-name='#{field_name}'].is-readonly")
      end
    end

    describe 'action - set_readonly' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:     'set_readonly',
                   set_readonly: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector("div[data-attribute-name='#{field_name}'].is-readonly")
      end
    end

    describe 'action - restrict values' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:     'set_fixed_to',
                   set_fixed_to: %w[key_1 key_3]
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector("select[name='#{field_name}'] option[value='key_1']")
        expect(page).to have_no_selector("select[name='#{field_name}'] option[value='key_2']")
        expect(page).to have_selector("select[name='#{field_name}'] option[value='key_3']")
      end
    end

    describe 'action - select' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'select',
                   select:   ['key_3']
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector("select[name='#{field_name}'] option[value='key_3'][selected]")
      end
    end

    describe 'action - auto select' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:     'set_fixed_to',
                   set_fixed_to: ['', 'key_3'],
                 },
               })
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:    'auto_select',
                   auto_select: 'true',
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector("select[name='#{field_name}'] option[value='key_3'][selected]")
      end
    end
  end

  describe 'modify multiselect attribute', authenticated_as: :authenticate, db_strategy: :reset do
    def authenticate
      create(:object_manager_attribute_multiselect, object_name: object_name, name: field_name, display: field_name, screens: screens)
      ObjectManager::Attribute.migration_execute
      true
    end

    describe 'action - show' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'show',
                   show:     'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector("select[name='#{field_name}']")
      end
    end

    describe 'action - hide' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'hide',
                   hide:     'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector(".form-group[data-attribute-name='#{field_name}'].is-hidden", visible: :hidden)
      end
    end

    describe 'action - remove' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'remove',
                   remove:   'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector(".form-group[data-attribute-name='#{field_name}'].is-removed", visible: :hidden)
      end
    end

    describe 'action - set_optional' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:     'set_optional',
                   set_optional: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page.find("div[data-attribute-name='#{field_name}'] div.formGroup-label label")).to have_no_text('*')
      end
    end

    describe 'action - set_mandatory' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:      'set_mandatory',
                   set_mandatory: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page.find("div[data-attribute-name='#{field_name}'] div.formGroup-label label")).to have_text('*')
      end
    end

    describe 'action - unset_readonly' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:       'unset_readonly',
                   unset_readonly: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_no_selector("div[data-attribute-name='#{field_name}'].is-readonly")
      end
    end

    describe 'action - set_readonly' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:     'set_readonly',
                   set_readonly: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector("div[data-attribute-name='#{field_name}'].is-readonly")
      end
    end

    describe 'action - restrict values' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:     'set_fixed_to',
                   set_fixed_to: %w[key_1 key_3]
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector("select[name='#{field_name}'] option[value='key_1']")
        expect(page).to have_no_selector("select[name='#{field_name}'] option[value='key_2']")
        expect(page).to have_selector("select[name='#{field_name}'] option[value='key_3']")
      end
    end

    describe 'action - select' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'select',
                   select:   ['key_3']
                 },
               })
      end

      it 'does perform' do
        before_it.call
        wait.until { page.find("select[name='#{field_name}']").value == ['key_3'] }
        expect(page.find("select[name='#{field_name}']").value).to eq(['key_3'])
      end
    end

    describe 'action - auto select' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:     'set_fixed_to',
                   set_fixed_to: ['', 'key_3'],
                 },
               })
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:    'auto_select',
                   auto_select: 'true',
                 },
               })
      end

      it 'does perform' do
        before_it.call
        wait.until { page.find("select[name='#{field_name}']").value == ['key_3'] }
        expect(page.find("select[name='#{field_name}']").value).to eq(['key_3'])
      end
    end
  end

  describe 'modify boolean attribute', authenticated_as: :authenticate, db_strategy: :reset do
    def authenticate
      create(:object_manager_attribute_boolean, object_name: object_name, name: field_name, display: field_name, screens: screens)
      ObjectManager::Attribute.migration_execute
      true
    end

    describe 'action - show' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'show',
                   show:     'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector("select[name='#{field_name}']")
      end
    end

    describe 'action - hide' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'hide',
                   hide:     'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector(".form-group[data-attribute-name='#{field_name}'].is-hidden", visible: :hidden)
      end
    end

    describe 'action - remove' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'remove',
                   remove:   'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector(".form-group[data-attribute-name='#{field_name}'].is-removed", visible: :hidden)
      end
    end

    describe 'action - set_optional' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:     'set_optional',
                   set_optional: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page.find("div[data-attribute-name='#{field_name}'] div.formGroup-label label")).to have_no_text('*')
      end
    end

    describe 'action - set_mandatory' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:      'set_mandatory',
                   set_mandatory: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page.find("div[data-attribute-name='#{field_name}'] div.formGroup-label label")).to have_text('*')
      end
    end

    describe 'action - restrict values' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:     'set_fixed_to',
                   set_fixed_to: %w[false]
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector("select[name='#{field_name}'] option[value='false']")
        expect(page).to have_no_selector("select[name='#{field_name}'] option[value='true']")
      end
    end

    describe 'action - select' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'select',
                   select:   ['true']
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector("select[name='#{field_name}'] option[value='true'][selected]")
      end
    end

    describe 'action - auto select' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:     'set_fixed_to',
                   set_fixed_to: ['', 'false'],
                 },
               })
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:    'auto_select',
                   auto_select: 'true',
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector("select[name='#{field_name}'] option[value='false'][selected]")
      end
    end
  end

  describe 'modify tree select attribute', authenticated_as: :authenticate, db_strategy: :reset do
    def authenticate
      create(:object_manager_attribute_tree_select, object_name: object_name, name: field_name, display: field_name, screens: screens)
      ObjectManager::Attribute.migration_execute
      true
    end

    describe 'action - show' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'show',
                   show:     'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector("input[name='#{field_name}']", visible: :all)
      end
    end

    describe 'action - hide' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'hide',
                   hide:     'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector(".form-group[data-attribute-name='#{field_name}'].is-hidden", visible: :all)
      end
    end

    describe 'action - remove' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'remove',
                   remove:   'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector(".form-group[data-attribute-name='#{field_name}'].is-removed", visible: :hidden)
      end
    end

    describe 'action - set_optional' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:     'set_optional',
                   set_optional: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page.find("div[data-attribute-name='#{field_name}'] div.formGroup-label label")).to have_no_text('*')
      end
    end

    describe 'action - set_mandatory' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:      'set_mandatory',
                   set_mandatory: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page.find("div[data-attribute-name='#{field_name}'] div.formGroup-label label")).to have_text('*')
      end
    end

    describe 'action - unset_readonly' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:       'unset_readonly',
                   unset_readonly: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_no_selector("div[data-attribute-name='#{field_name}'].is-readonly")
      end
    end

    describe 'action - set_readonly' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:     'set_readonly',
                   set_readonly: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector("div[data-attribute-name='#{field_name}'].is-readonly")
      end
    end

    describe 'action - restrict values' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:     'set_fixed_to',
                   set_fixed_to: ['Incident', 'Incident::Hardware', 'Incident::Hardware::Monitor']
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector('span.searchableSelect-option-text', text: 'Incident', visible: :all)
        expect(page).to have_selector('span.searchableSelect-option-text', text: 'Hardware', visible: :all)
        expect(page).to have_selector('span.searchableSelect-option-text', text: 'Monitor', visible: :all)
        expect(page).to have_no_selector('span.searchableSelect-option-text', text: 'Mouse', visible: :all)
        expect(page).to have_no_selector('span.searchableSelect-option-text', text: 'Softwareproblem', visible: :all)
      end
    end

    describe 'action - select' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'select',
                   select:   ['Incident::Hardware::Monitor']
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector("input[name='#{field_name}'][value='Incident::Hardware::Monitor']", visible: :all)
      end
    end

    describe 'action - auto select' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:     'set_fixed_to',
                   set_fixed_to: ['', 'Incident'],
                 },
               })
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:    'auto_select',
                   auto_select: 'true',
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector("input[name='#{field_name}'][value='Incident']", visible: :all)
      end
    end
  end

  describe 'modify multi tree select attribute', authenticated_as: :authenticate, db_strategy: :reset do
    def authenticate
      create(:object_manager_attribute_multi_tree_select, object_name: object_name, name: field_name, display: field_name, screens: screens)
      ObjectManager::Attribute.migration_execute
      true
    end

    describe 'action - show' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'show',
                   show:     'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector("input[name='#{field_name}_completion']", visible: :all)
      end
    end

    describe 'action - hide' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'hide',
                   hide:     'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector(".form-group[data-attribute-name='#{field_name}'].is-hidden", visible: :all)
      end
    end

    describe 'action - remove' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'remove',
                   remove:   'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector(".form-group[data-attribute-name='#{field_name}'].is-removed", visible: :hidden)
      end
    end

    describe 'action - set_optional' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:     'set_optional',
                   set_optional: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page.find("div[data-attribute-name='#{field_name}'] div.formGroup-label label")).to have_no_text('*')
      end
    end

    describe 'action - set_mandatory' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:      'set_mandatory',
                   set_mandatory: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page.find("div[data-attribute-name='#{field_name}'] div.formGroup-label label")).to have_text('*')
      end
    end

    describe 'action - unset_readonly' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:       'unset_readonly',
                   unset_readonly: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_no_selector("div[data-attribute-name='#{field_name}'].is-readonly")
      end
    end

    describe 'action - set_readonly' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:     'set_readonly',
                   set_readonly: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector("div[data-attribute-name='#{field_name}'].is-readonly")
      end
    end

    describe 'action - restrict values' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:     'set_fixed_to',
                   set_fixed_to: ['Incident', 'Incident::Hardware', 'Incident::Hardware::Monitor']
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector('span.searchableSelect-option-text', text: 'Incident', visible: :all)
        expect(page).to have_selector('span.searchableSelect-option-text', text: 'Hardware', visible: :all)
        expect(page).to have_selector('span.searchableSelect-option-text', text: 'Monitor', visible: :all)
        expect(page).to have_no_selector('span.searchableSelect-option-text', text: 'Mouse', visible: :all)
        expect(page).to have_no_selector('span.searchableSelect-option-text', text: 'Softwareproblem', visible: :all)
      end
    end

    describe 'action - select' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'select',
                   select:   ['Incident::Hardware::Monitor']
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector('span.token-label', text: 'Incident › Hardware › Monitor')
      end
    end

    describe 'action - auto select' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:     'set_fixed_to',
                   set_fixed_to: ['', 'Incident'],
                 },
               })
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:    'auto_select',
                   auto_select: 'true',
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector('span.token-label', text: 'Incident')
      end
    end
  end

  describe 'modify date attribute', authenticated_as: :authenticate, db_strategy: :reset do
    def authenticate
      create(:object_manager_attribute_date, object_name: object_name, name: field_name, display: field_name, screens: screens)
      ObjectManager::Attribute.migration_execute
      true
    end

    describe 'action - show' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'show',
                   show:     'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector(".form-group[data-attribute-name='#{field_name}']")
      end
    end

    describe 'action - hide' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'hide',
                   hide:     'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector(".form-group[data-attribute-name='#{field_name}'].is-hidden", visible: :hidden)
      end
    end

    describe 'action - remove' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'remove',
                   remove:   'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector(".form-group[data-attribute-name='#{field_name}'].is-removed", visible: :hidden)
      end
    end

    describe 'action - set_optional' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:     'set_optional',
                   set_optional: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page.find("div[data-attribute-name='#{field_name}'] div.formGroup-label label")).to have_no_text('*')
      end
    end

    describe 'action - set_mandatory' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:      'set_mandatory',
                   set_mandatory: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page.find("div[data-attribute-name='#{field_name}'] div.formGroup-label label")).to have_text('*')
      end
    end

    describe 'action - unset_readonly' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:       'unset_readonly',
                   unset_readonly: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_no_selector("div[data-attribute-name='#{field_name}'].is-readonly")
      end
    end

    describe 'action - set_readonly' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:     'set_readonly',
                   set_readonly: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector("div[data-attribute-name='#{field_name}'].is-readonly")
      end
    end
  end

  describe 'modify datetime attribute', authenticated_as: :authenticate, db_strategy: :reset do
    def authenticate
      create(:object_manager_attribute_datetime, object_name: object_name, name: field_name, display: field_name, screens: screens)
      ObjectManager::Attribute.migration_execute
      true
    end

    describe 'action - show' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'show',
                   show:     'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector(".form-group[data-attribute-name='#{field_name}']")
      end
    end

    describe 'action - hide' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'hide',
                   hide:     'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector(".form-group[data-attribute-name='#{field_name}'].is-hidden", visible: :hidden)
      end
    end

    describe 'action - remove' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator: 'remove',
                   remove:   'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector(".form-group[data-attribute-name='#{field_name}'].is-removed", visible: :hidden)
      end
    end

    describe 'action - set_optional' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:     'set_optional',
                   set_optional: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page.find("div[data-attribute-name='#{field_name}'] div.formGroup-label label")).to have_no_text('*')
      end
    end

    describe 'action - set_mandatory' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:      'set_mandatory',
                   set_mandatory: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page.find("div[data-attribute-name='#{field_name}'] div.formGroup-label label")).to have_text('*')
      end
    end

    describe 'action - unset_readonly' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:       'unset_readonly',
                   unset_readonly: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_no_selector("div[data-attribute-name='#{field_name}'].is-readonly")
      end
    end

    describe 'action - set_readonly' do
      before do
        create(:core_workflow,
               object:  object_name,
               perform: {
                 "#{object_name.downcase}.#{field_name}": {
                   operator:     'set_readonly',
                   set_readonly: 'true'
                 },
               })
      end

      it 'does perform' do
        before_it.call
        expect(page).to have_selector("div[data-attribute-name='#{field_name}'].is-readonly")
      end
    end
  end

  describe 'Unable to close tickets in certran cases if core workflow is used #3710', authenticated_as: :authenticate, db_strategy: :reset do
    def authenticate
      create(:object_manager_attribute_text, object_name: object_name, name: field_name, display: field_name, screens: screens)
      ObjectManager::Attribute.migration_execute
      true
    end

    before do
      create(:core_workflow,
             object:  object_name,
             perform: {
               "#{object_name.downcase}.#{field_name}": {
                 operator:      'set_mandatory',
                 set_mandatory: 'true'
               },
             })
      create(:core_workflow,
             object:  object_name,
             perform: {
               "#{object_name.downcase}.#{field_name}": {
                 operator: 'hide',
                 hide:     'true'
               },
             })
    end

    it 'does not display hidden fields as mandatory' do
      before_it.call
      expect(page.find("input[name='#{field_name}']", visible: :hidden)[:required]).not_to eq('true')
    end
  end
end
