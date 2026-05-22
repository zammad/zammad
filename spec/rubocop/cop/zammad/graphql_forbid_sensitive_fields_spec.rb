# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative '../../../../.dev/rubocop/cop/zammad/graphql_forbid_sensitive_fields'

RSpec.describe RuboCop::Cop::Zammad::GraphqlForbidSensitiveFields, :aggregate_failures, type: :rubocop do
  it 'highlights the field name symbol and reports the field name in the message' do
    expect_offense(<<~RUBY)
      field :password, String, null: true
            ^^^^^^^^^ Avoid declaring sensitive field `:password` in a GraphQL return type [...]
    RUBY
  end

  # One representative name per sensitive substring family.
  %i[
    password passphrase secret_value api_token api_key private_key
    encrypted_blob password_salt ssl_certificate idp_cert otp_secret
    ssn cvv cvc credentials bind_pw
  ].each do |name|
    it "rejects `field :#{name}`" do
      result = inspect_source("field :#{name}, String, null: true")
      expect(result.first&.cop_name).to eq('Zammad/GraphqlForbidSensitiveFields')
    end
  end

  # Non-sensitive look-alikes that previously tripped the `_key` substring or
  # are otherwise common field names.
  %i[name email keywords key cache_key foreign_key create_article_type_key].each do |name|
    it "accepts `field :#{name}`" do
      expect_no_offenses("field :#{name}, String, null: true")
    end
  end

  it 'also matches the relation helpers belongs_to / has_one / lookup_field' do
    %w[belongs_to has_one lookup_field].each do |helper|
      result = inspect_source("#{helper} :api_key, SomeType")
      expect(result.first&.cop_name).to eq('Zammad/GraphqlForbidSensitiveFields')
    end
  end

  it 'ignores `argument` declarations (input objects use argument, not field)' do
    expect_no_offenses('argument :password, String, required: true')
  end

  it 'ignores `field` calls with a receiver (not the GraphQL DSL)' do
    expect_no_offenses('foo.field :password')
  end
end
