# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Every action gets a field of its own (see CoreWorkflowFieldMatrix), so one page
#   load checks all actions of an attribute type.
RSpec.shared_examples 'core workflow' do
  include CoreWorkflowFieldMatrix

  def authenticate
    create_matrix_fields
    true
  end

  def visit_form
    before_it.call
    wait_for_core_workflow
  end

  def form_group(action)
    ".form-group[data-attribute-name='#{matrix_field(action)}']"
  end

  def field_label(action)
    page.find("div[data-attribute-name='#{matrix_field(action)}'] div.formGroup-label label")
  end

  def expect_field_state_actions(hidden_visibility: :hidden, readonly: true)
    expect(page).to have_css(form_group(:show))
    expect(page).to have_css("#{form_group(:hide)}.is-hidden", visible: hidden_visibility)
    expect(page).to have_css("#{form_group(:remove)}.is-removed", visible: :hidden)
    expect(field_label(:set_optional)).to have_no_text('*')
    expect(field_label(:set_mandatory)).to have_text('*')

    return if !readonly

    expect(page).to have_css(form_group(:unset_readonly))
    expect(page).to have_no_css("div[data-attribute-name='#{matrix_field(:unset_readonly)}'].is-readonly")
    expect(page).to have_css("div[data-attribute-name='#{matrix_field(:set_readonly)}'].is-readonly")
  end

  def expect_fill_in_actions
    expect(page).to have_field(matrix_field(:fill_in), with: '4cddb2twza', exact: true)
    expect(page).to have_field(matrix_field(:fill_in_empty_with_match), with: '9999', exact: true)
    expect(page).to have_field(matrix_field(:fill_in_empty_without_match), with: '4cddb2twza', exact: true)
  end

  def expect_restricted_tree_options
    within(form_group(:restrict_values)) do
      expect(page).to have_css('span.searchableSelect-option-text', text: 'Incident', visible: :all)
      expect(page).to have_css('span.searchableSelect-option-text', text: 'Hardware', visible: :all)
      expect(page).to have_css('span.searchableSelect-option-text', text: 'Monitor', visible: :all)
      expect(page).to have_no_css('span.searchableSelect-option-text', text: 'Mouse', visible: :all)
      expect(page).to have_no_css('span.searchableSelect-option-text', text: 'Softwareproblem', visible: :all)
    end
  end

  describe 'modify input attribute', authenticated_as: :authenticate, db_strategy: :reset do
    let(:matrix_type) { :input }

    before { create_matrix_workflows }

    it 'performs every action', :aggregate_failures do
      visit_form

      expect(page).to have_css("input[name='#{matrix_field(:show)}']")
      expect_field_state_actions
      expect_fill_in_actions
    end
  end

  describe 'modify textarea attribute', authenticated_as: :authenticate, db_strategy: :reset do
    let(:matrix_type) { :textarea }

    before { create_matrix_workflows }

    it 'performs every action', :aggregate_failures do
      visit_form

      expect(page).to have_css("textarea[name='#{matrix_field(:show)}']")
      expect_field_state_actions
      expect_fill_in_actions
    end
  end

  describe 'modify select attribute', authenticated_as: :authenticate, db_strategy: :reset do
    let(:matrix_type) { :select }

    before { create_matrix_workflows }

    it 'performs every action', :aggregate_failures do
      visit_form

      expect(page).to have_css("select[name='#{matrix_field(:show)}']")
      expect_field_state_actions
      expect(page).to have_css("select[name='#{matrix_field(:restrict_values)}'] option[value='key_1']")
      expect(page).to have_no_css("select[name='#{matrix_field(:restrict_values)}'] option[value='key_2']")
      expect(page).to have_css("select[name='#{matrix_field(:restrict_values)}'] option[value='key_3']")
      expect(page).to have_css("select[name='#{matrix_field(:select)}'] option[value='key_3'][selected]")
      expect(page).to have_css("select[name='#{matrix_field(:auto_select)}'] option[value='key_3'][selected]")
    end
  end

  describe 'modify multiselect attribute', authenticated_as: :authenticate, db_strategy: :reset do
    let(:matrix_type) { :multiselect }

    before { create_matrix_workflows }

    it 'performs every action', :aggregate_failures do
      visit_form

      expect(page).to have_css("select[name='#{matrix_field(:show)}']")
      expect_field_state_actions
      expect(page).to have_css("select[name='#{matrix_field(:restrict_values)}'] option[value='key_1']")
      expect(page).to have_no_css("select[name='#{matrix_field(:restrict_values)}'] option[value='key_2']")
      expect(page).to have_css("select[name='#{matrix_field(:restrict_values)}'] option[value='key_3']")
      expect(page).to have_select(matrix_field(:select), selected: ['value_3'])
      expect(page).to have_select(matrix_field(:auto_select), selected: ['value_3'])
    end
  end

  describe 'modify boolean attribute', authenticated_as: :authenticate, db_strategy: :reset do
    let(:matrix_type) { :boolean }

    before { create_matrix_workflows }

    it 'performs every action', :aggregate_failures do
      visit_form

      expect(page).to have_css("select[name='#{matrix_field(:show)}']")
      expect_field_state_actions(readonly: false)
      expect(page).to have_css("select[name='#{matrix_field(:restrict_values)}'] option[value='false']")
      expect(page).to have_no_css("select[name='#{matrix_field(:restrict_values)}'] option[value='true']")
      expect(page).to have_css("select[name='#{matrix_field(:select)}'] option[value='true'][selected]")
      expect(page).to have_css("select[name='#{matrix_field(:auto_select)}'] option[value='false'][selected]")
    end
  end

  describe 'modify tree select attribute', authenticated_as: :authenticate, db_strategy: :reset do
    let(:matrix_type) { :tree_select }

    before { create_matrix_workflows }

    it 'performs every action', :aggregate_failures do
      visit_form

      expect(page).to have_css("input[name='#{matrix_field(:show)}']", visible: :all)
      expect_field_state_actions(hidden_visibility: :all)
      expect_restricted_tree_options
      expect(page).to have_css("input[name='#{matrix_field(:select)}'][value='Incident::Hardware::Monitor']", visible: :all)
      expect(page).to have_css("input[name='#{matrix_field(:auto_select)}'][value='Incident']", visible: :all)
    end
  end

  describe 'modify multi tree select attribute', authenticated_as: :authenticate, db_strategy: :reset do
    let(:matrix_type) { :multi_tree_select }

    before { create_matrix_workflows }

    it 'performs every action', :aggregate_failures do
      visit_form

      expect(page).to have_css("input[name='#{matrix_field(:show)}_completion']", visible: :all)
      expect_field_state_actions(hidden_visibility: :all)
      expect_restricted_tree_options
      within(form_group(:select)) do
        expect(page).to have_css('span.token-label', text: 'Incident › Hardware › Monitor')
      end
      within(form_group(:auto_select)) do
        expect(page).to have_css('span.token-label', text: 'Incident')
      end
    end
  end

  describe 'modify date attribute', authenticated_as: :authenticate, db_strategy: :reset do
    let(:matrix_type) { :date }

    before { create_matrix_workflows }

    it 'performs every action', :aggregate_failures do
      visit_form

      expect(page).to have_css(form_group(:show))
      expect_field_state_actions
    end
  end

  describe 'modify datetime attribute', authenticated_as: :authenticate, db_strategy: :reset do
    let(:matrix_type) { :datetime }

    before { create_matrix_workflows }

    it 'performs every action', :aggregate_failures do
      visit_form

      expect(page).to have_css(form_group(:show))
      expect_field_state_actions
    end
  end

  describe 'Unable to close tickets in certran cases if core workflow is used #3710', authenticated_as: :authenticate, db_strategy: :reset do
    def authenticate
      create(:object_manager_attribute_text, object_name: object_name, name: matrix_field(:hidden_mandatory), display: matrix_field(:hidden_mandatory), screens: CoreWorkflowFieldMatrix::SCREENS)
      ObjectManager::Attribute.migration_execute
      true
    end

    before do
      create(:core_workflow,
             object:  object_name,
             perform: {
               "#{object_name.downcase}.#{matrix_field(:hidden_mandatory)}": {
                 operator:      'set_mandatory',
                 set_mandatory: 'true'
               },
             })
      create(:core_workflow,
             object:  object_name,
             perform: {
               "#{object_name.downcase}.#{matrix_field(:hidden_mandatory)}": {
                 operator: 'hide',
                 hide:     'true'
               },
             })
    end

    it 'does not display hidden fields as mandatory' do
      visit_form
      expect(page).to have_css("input[name='#{matrix_field(:hidden_mandatory)}']:not([required])", visible: :hidden)
    end
  end
end
