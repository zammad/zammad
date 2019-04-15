require 'rails_helper'
require 'byebug'

RSpec.describe 'Text Module', type: :request do

  let(:admin_user) do
    create(:admin_user)
  end
  let(:agent_user) do
    create(:agent_user)
  end
  let(:customer_user) do
    create(:customer_user)
  end

  describe 'request handling' do

    it 'does csv example - customer no access' do
      authenticated_as(customer_user)
      get '/api/v1/text_modules/import_example', as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq('Not authorized (user)!')
    end

    it 'does csv example - admin access' do
      TextModule.load('en-en')

      authenticated_as(admin_user)
      get '/api/v1/text_modules/import_example', as: :json
      expect(response).to have_http_status(:ok)
      rows = CSV.parse(@response.body)
      header = rows.shift

      expect(header[0]).to eq('id')
      expect(header[1]).to eq('name')
      expect(header[2]).to eq('keywords')
      expect(header[3]).to eq('content')
      expect(header[4]).to eq('note')
      expect(header[5]).to eq('active')
      expect(header).not_to include('organization')
      expect(header).not_to include('priority')
      expect(header).not_to include('state')
      expect(header).not_to include('owner')
      expect(header).not_to include('customer')
    end

    it 'does csv import - admin access' do

      # invalid file
      csv_file = fixture_file_upload('csv_import/text_module/simple_col_not_existing.csv', 'text/csv')

      authenticated_as(admin_user)
      post '/api/v1/text_modules/import', params: { try: true, file: csv_file, col_sep: ';' }
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)

      expect(json_response['try']).to be_truthy
      expect(json_response['records'].count).to eq(2)
      expect(json_response['result']).to eq('failed')
      expect(json_response['errors'].count).to eq(2)
      expect(json_response['errors'][0]).to eq("Line 1: Unable to create record - unknown attribute 'keywords2' for TextModule.")
      expect(json_response['errors'][1]).to eq("Line 2: Unable to create record - unknown attribute 'keywords2' for TextModule.")

      # valid file try
      csv_file = fixture_file_upload('csv_import/text_module/simple.csv', 'text/csv')
      post '/api/v1/text_modules/import?try=true', params: { file: csv_file, col_sep: ';' }
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)

      expect(json_response['try']).to be_truthy
      expect(json_response['records'].count).to eq(2)
      expect(json_response['result']).to eq('success')

      expect(TextModule.find_by(name: 'some name1')).to be_nil
      expect(TextModule.find_by(name: 'some name2')).to be_nil

      # valid file
      csv_file = fixture_file_upload('csv_import/text_module/simple.csv', 'text/csv')
      post '/api/v1/text_modules/import', params: { file: csv_file, col_sep: ';' }
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)

      expect(json_response['try']).to eq(false)
      expect(json_response['records'].count).to eq(2)
      expect(json_response['result']).to eq('success')

      text_module1 = TextModule.find_by(name: 'some name1')
      expect(text_module1).to be_truthy
      expect(text_module1.name).to eq('some name1')
      expect(text_module1.keywords).to eq('keyword1')
      expect(text_module1.content).to eq('some<br>content1')
      expect(text_module1.active).to be_truthy
      text_module2 = TextModule.find_by(name: 'some name2')
      expect(text_module2).to be_truthy
      expect(text_module2.name).to eq('some name2')
      expect(text_module2.keywords).to eq('keyword2')
      expect(text_module2.content).to eq('some content<br>test123')
      expect(text_module2.active).to be_truthy
    end
  end
end
