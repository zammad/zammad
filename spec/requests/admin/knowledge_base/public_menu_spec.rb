# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Admin Knowledge Base Public Menu', type: :request, authenticated_as: :current_user do
  let(:url)    { "/api/v1/knowledge_bases/manage/#{knowledge_base.id}/update_menu_items" }
  let(:params) do
    {
      menu_items_sets: [{
        kb_locale_id: kb_locale.id,
        location:     location,
        menu_items:   menu_items
      }]
    }
  end

  let(:current_user)   { create(:admin) }
  let(:menu_item)      { create(:knowledge_base_menu_item) }
  let(:kb_locale)      { menu_item.kb_locale }
  let(:knowledge_base) { kb_locale.knowledge_base }
  let(:location)       { 'header' }

  it 'edit title' do
    attrs = to_params(menu_item)
    attrs[:title] = 'new title'

    params = build_params([attrs])

    expect { make_request(params) }.to change { menu_item.reload.title }.to 'new title'
  end

  it 'delete item' do
    attrs = to_params(menu_item)
    attrs[:_destroy] = true

    params = build_params([attrs])

    expect { make_request(params) }.to change { KnowledgeBase::MenuItem.count }.by(-1)
  end

  it 'add item' do
    new_item = {
      title:   'new item',
      new_tab: false,
      url:     '/new_url'
    }

    params = build_params([to_params(menu_item), new_item])

    expect { make_request(params) }.to change { KnowledgeBase::MenuItem.count }.by(1)
  end

  def to_params(item)
    item.slice :id, :title, :url, :new_tab
  end

  def make_request(params)
    patch url, params: params, as: :json
  end

  def build_params(menu_items)
    {
      menu_items_sets: [{
        kb_locale_id: kb_locale.id,
        location:     location,
        menu_items:   menu_items
      }]
    }
  end
end
