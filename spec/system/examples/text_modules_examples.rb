# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'text modules' do |path:|

  let!(:group1)                    { create :group }
  let!(:group2)                    { create :group }
  let!(:text_module_without_group) { create :text_module }
  let!(:text_module_group1)        { create :text_module, groups: [group1] }
  let!(:text_module_group2)        { create :text_module, groups: [group2] }

  it 'shows when send ::' do
    refresh # workaround to get new created objects from db
    visit path
    within(:active_content) do
      find('select[name="group_id"]').select(1)
      find(:richtext).send_keys(':')
      find(:richtext).send_keys(':')
      expect(page).to have_selector(:text_module, text_module_without_group.id)
    end
  end

  it 'does not show when send :enter:' do
    visit path
    within(:active_content) do
      find('select[name="group_id"]').select(1)
      find(:richtext).send_keys(':')
      find(:richtext).send_keys(:enter)
      find(:richtext).send_keys(':')
      expect(page).to have_no_selector(:text_module, text_module_without_group.id)
    end
  end

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

    refresh # workaround to get changed settings from db
    visit path
    within(:active_content) do
      find('select[name="group_id"]').select(group1.name)
      find(:richtext).send_keys('::')

      expect(page).to have_selector(:text_module, text_module_without_group.id)
      expect(page).to have_selector(:text_module, text_module_group1.id)
      expect(page).to have_no_selector(:text_module, text_module_group2.id)

      find('select[name="group_id"]').select(group2.name)
      find(:richtext).send_keys('::')

      expect(page).to have_selector(:text_module, text_module_without_group.id)
      expect(page).to have_no_selector(:text_module, text_module_group1.id)
      expect(page).to have_selector(:text_module, text_module_group2.id)
    end
  end
end
