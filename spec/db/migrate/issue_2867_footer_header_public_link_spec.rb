# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue2867FooterHeaderPublicLink, type: :db_migration, db_strategy: :reset do

  before { without_column(table, column: column) }

  let(:table)   { :knowledge_base_menu_items }
  let(:column)  { :location }

  it 'adds an index' do
    expect { migrate }.to change { index_exists?(table, column) }.to(true)
  end

  it 'sets no default' do
    expect { migrate }
      .not_to change {
        KnowledgeBase::MenuItem.reset_column_information
        KnowledgeBase::MenuItem.column_defaults['location']
      }.from(nil)
  end

  it 'sets location for existing items' do
    # create menu item without touching location column
    menu_item = KnowledgeBase::MenuItem.acts_as_list_no_update do
      attrs = attributes_for(:knowledge_base_menu_item)
      attrs.delete :location

      item = KnowledgeBase::MenuItem.new(attrs)
      item.position = 0
      item.kb_locale = create(:knowledge_base).kb_locales.first
      item.save(validate: false)

      item
    end

    expect { migrate }.to change { menu_item.reload.attributes['location'] }.from(nil).to('header')
  end
end
