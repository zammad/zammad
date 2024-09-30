# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'ChecklistTemplates', current_user_id: 1, type: :request do
  let(:unauthorized_user) { create(:agent) }
  let(:authorized_user)   { create(:admin) }

  describe '#index' do
    before do
      create_list(:checklist_template, 10)

      get '/api/v1/checklist_templates'
    end

    context 'when user is not authenticated', authenticated_as: :unauthorized_user do
      let(:unauthorized_user) { create(:customer) }

      it 'returns forbidden status' do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user is authenticated', authenticated_as: :authorized_user do
      it 'returns ok status' do
        expect(response).to have_http_status(:ok)
      end

      context 'when no template was created' do
        it 'returns checklist templates' do
          expect(json_response.length).to eq(10)
        end
      end
    end
  end

  describe '#show' do
    let(:checklist_template) { create(:checklist_template) }

    before do
      get "/api/v1/checklist_templates/#{checklist_template.id}"
    end

    context 'when user is not authenticated', authenticated_as: :unauthorized_user do
      let(:unauthorized_user) { create(:customer) }

      it 'returns forbidden status' do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user is authenticated', authenticated_as: :authorized_user do
      it 'returns ok status' do
        expect(response).to have_http_status(:ok)
      end

      context 'when checklist template was created' do
        it 'returns checklist template' do
          expect(json_response.except(:created_at, :updated_at)).to include(checklist_template.attributes_with_association_ids.except(:created_at, :updated_at))
        end
      end

      context 'when checklist template was not found' do
        let(:checklist_template) { create(:checklist) }

        it 'returns not found status' do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe '#create' do
    let(:checklist_template_params) do
      {
        name:   Faker::Name.unique.name,
        items:  [
          Faker::Lorem.unique.sentence,
          Faker::Lorem.unique.sentence,
          Faker::Lorem.unique.sentence,
        ],
        active: true,
      }
    end

    before do
      post '/api/v1/checklist_templates', params: checklist_template_params
    end

    context 'when user is not authenticated', authenticated_as: :unauthorized_user do
      it 'returns forbidden status' do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user is authenticated', authenticated_as: :authorized_user do
      it 'returns created status' do
        expect(response).to have_http_status(:created)
      end

      context 'when checklist template was created' do
        it 'returns checklist template' do
          expect(json_response.except(:created_at, :updated_at)).to include(ChecklistTemplate.last.attributes_with_association_ids.except(:created_at, :updated_at))
        end
      end
    end
  end

  describe '#update' do
    let(:checklist_template) { create(:checklist_template) }
    let(:checklist_template_params) do
      {
        'name'   => 'Updated Checklist',
        'active' => false,
      }
    end

    before do
      put "/api/v1/checklist_templates/#{checklist_template.id}", params: checklist_template_params
    end

    context 'when user is not authenticated', authenticated_as: :unauthorized_user do
      it 'returns forbidden status' do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user is authenticated', authenticated_as: :authorized_user do
      it 'returns ok status' do
        expect(response).to have_http_status(:ok)
      end

      context 'when checklist template was updated' do
        it 'returns updated checklist template' do
          expect(json_response.except(:created_at, :updated_at)).to include(checklist_template_params)
        end
      end

      context 'when checklist template was not found' do
        let(:checklist_template) { create(:checklist) }

        it 'returns not found status' do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe '#destroy' do
    let(:checklist_template) { create(:checklist_template) }

    before do
      delete "/api/v1/checklist_templates/#{checklist_template.id}"
    end

    context 'when user is not authenticated', authenticated_as: :unauthorized_user do
      it 'returns forbidden status' do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user is authenticated', authenticated_as: :authorized_user do
      it 'returns no content status' do
        expect(response).to have_http_status(:ok)
      end

      context 'when checklist template was destroyed' do
        it 'returns no content status' do
          expect { checklist_template.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when checklist template was not found' do
        let(:checklist_template) { create(:checklist) }

        it 'returns not found status' do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
