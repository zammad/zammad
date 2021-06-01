# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue2140ResetLdapConfig, type: :db_migration do
  before { Setting.set('ldap_config', config) }

  context 'when LDAP config isn’t broken' do
    let(:config) do
      { 'wizardData' =>
                        { 'backend_user_attributes' =>
                                                       { 'foo' => 'bar' },
                          'user_attributes'         =>
                                                       { 'baz' => 'qux' } } }.with_indifferent_access
    end

    it 'makes no changes' do
      expect { migrate }.not_to change { Setting.get('ldap_config') }
    end
  end

  context 'when LDAP config was assumed to be broken' do
    let(:config) do
      { 'wizardData' =>
                        { 'backend_user_attributes' =>
                                                       { 'foo' => "\u0001\u0001\u0004€" },
                          'user_attributes'         =>
                                                       { 'baz' => 'qux' } } }.with_indifferent_access
    end

    it 'makes no changes' do
      expect { migrate }.not_to change { Setting.get('ldap_config') }
    end
  end
end
