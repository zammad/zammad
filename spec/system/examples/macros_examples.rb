# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'macros' do |path:|

  let!(:group1)              { create :group }
  let!(:group2)              { create :group }
  let!(:macro_without_group) { create :macro }
  let!(:macro_group1)        { create :macro, groups: [group1] }
  let!(:macro_group2)        { create :macro, groups: [group2] }

  it 'supports group-dependent macros' do

    # give user access to all groups including those created
    # by using FactoryBot outside of the example
    group_names_access_map = Group.all.pluck(:name).each_with_object({}) do |group_name, result|
      result[group_name] = 'full'.freeze
    end

    current_user do |user|
      user.group_names_access_map = group_names_access_map
      user.save!
    end

    # refresh browser to get macro accessable
    refresh
    visit path

    within(:active_content) do

      # select group
      find('select[name="group_id"]').select(group1.name)

      open_macro_list
      expect(page).to have_selector(:macro, macro_without_group.id)
      expect(page).to have_selector(:macro, macro_group1.id)
      expect(page).to have_no_selector(:macro, macro_group2.id)

      # select group
      find('select[name="group_id"]').select(group2.name)

      open_macro_list
      expect(page).to have_selector(:macro, macro_without_group.id)
      expect(page).to have_no_selector(:macro, macro_group1.id)
      expect(page).to have_selector(:macro, macro_group2.id)
    end
  end
end
