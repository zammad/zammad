# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe MigrateTemplateOptions, type: :db_migration do
  let!(:template) { create(:template) }

  context 'with new options' do
    it 'keeps new options unchanged' do
      expect { migrate }.not_to change(template, :options)
    end
  end

  context 'with old options' do
    let!(:template)   { create(:template, options: old_options) }
    let(:customer)    { create(:customer) }
    let(:old_options) do
      {
        title:                  'Bar',
        customer_id:            customer.id.to_s,
        customer_id_completion: "#{customer.firstname} #{customer.lastname} <#{customer.email}>",
        body:                   'abc'
      }
    end
    let(:new_options) do
      {
        'ticket.title'       => { 'value' => 'Bar' },
        'ticket.customer_id' => {
          'value'            => customer.id.to_s,
          'value_completion' => "#{customer.firstname} #{customer.lastname} <#{customer.email}>",
        },
        'article.body'       => { 'value' => 'abc' }
      }
    end

    it 'migrates them' do
      expect { migrate }.to change { template.reload.options }.from(old_options).to(new_options)
    end
  end
end
