# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'KnowledgeBase answer attachments cloning', type: :request, authenticated_as: :current_user do
  include_context 'basic Knowledge Base' do
    before do
      published_answer
    end
  end

  let(:current_user) { create(:agent) }

  it 'copies to given UploadCache' do
    form_id  = Random.rand(999..9999)
    endpoint = "/api/v1/knowledge_bases/#{knowledge_base.id}/answers/#{published_answer.id}/attachments/clone_to_form"
    params   = { form_id: form_id }

    expect { post endpoint, params: params }
      .to change { Store.list(object: 'UploadCache', o_id: form_id).count }
      .from(0)
      .to(1)
  end
end
