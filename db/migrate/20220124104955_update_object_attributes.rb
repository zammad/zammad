# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class UpdateObjectAttributes < ActiveRecord::Migration[6.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    # rubocop:disable Lint/BooleanSymbol
    object_attributes_update = [
      {
        object:      'Organization',
        name:        'domain_assignment',
        data_option: {
          null:       true,
          default:    false,
          note:       'Assign users based on user domain.',
          item_class: 'formGroup--halfSize',
          options:    {
            true:  'yes',
            false: 'no',
          },
          translate:  true,
          permission: ['admin.organization'],
        },
      },
      {
        object:  'TicketArticle',
        name:    'cc',
        display: 'CC',
      },
      {
        object:      'Organization',
        name:        'shared',
        data_option: {
          null:       true,
          default:    true,
          note:       "Customers in the organization can view each other's items.",
          item_class: 'formGroup--halfSize',
          options:    {
            true:  'yes',
            false: 'no',
          },
          translate:  true,
          permission: ['admin.organization'],
        },
      },
      {
        object:  'User',
        name:    'firstname',
        display: 'First name',
      },
      {
        object:  'User',
        name:    'lastname',
        display: 'Last name',
      },
    ]
    # rubocop:enable Lint/BooleanSymbol

    object_attributes_update.each do |attribute|
      fetched_attribute = ObjectManager::Attribute.get(name: attribute[:name], object: attribute[:object])
      next if !fetched_attribute

      if attribute[:display]
        # p "Updating display of #{attribute[:name]} to #{attribute[:display]}"
        fetched_attribute.display = attribute[:display]
      end

      if attribute[:data_option]
        # p "Updating data_option of #{attribute[:name]} to #{attribute[:data_option]}"
        fetched_attribute.data_option = attribute[:data_option]
      end

      fetched_attribute.save!
    end
  end
end
