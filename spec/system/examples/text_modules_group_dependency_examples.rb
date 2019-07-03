RSpec.shared_examples 'group-dependent text modules' do |path:|

  let!(:group1)                    { create :group }
  let!(:group2)                    { create :group }
  let!(:text_module_without_group) { create :text_module }
  let!(:text_module_group1)        { create :text_module, groups: [group1] }
  let!(:text_module_group2)        { create :text_module, groups: [group2] }

  it 'supports group-dependent text modules' do

    # give user access to all groups including those created
    # by using FactoryBot outside of the example
    group_names_access_map = Group.all.pluck(:name).each_with_object({}) do |group_name, result|
      result[group_name] = 'full'.freeze
    end

    current_user do |user|
      user.group_names_access_map = group_names_access_map
      user.save!
    end

    visit path

    within(:active_content) do

      selector_group_select          = 'select[name="group_id"]'
      selector_text_module_selection = '.shortcut'
      selector_text_module_item      = ".shortcut > ul > li[data-id='%s']"

      # exercise
      find(selector_group_select).find(:option, group1.name).select_option
      find(:richtext).send_keys('::')

      # expectations
      expect(page).to have_css(selector_text_module_selection, wait: 3)
      expect(page).to have_css(format(selector_text_module_item, text_module_without_group.id))
      expect(page).to have_css(format(selector_text_module_item, text_module_group1.id))
      expect(page).to have_no_css(format(selector_text_module_item, text_module_group2.id))

      # exercise
      find(selector_group_select).find(:option, group2.name).select_option
      find(:richtext).send_keys('::')

      # expectations
      expect(page).to have_css(selector_text_module_selection, wait: 3)
      expect(page).to have_css(format(selector_text_module_item, text_module_without_group.id))
      expect(page).to have_no_css(format(selector_text_module_item, text_module_group1.id))
      expect(page).to have_css(format(selector_text_module_item, text_module_group2.id))
    end
  end
end
