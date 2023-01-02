# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue4049FixObjectLookup, type: :db_migration do
  before do
    # create and update to wrong state in pre release
    ObjectLookup.by_name('SMIMECertificate')
    ObjectLookup.find_by(name: 'SMIMECertificate').update(name: 'SmimeCertificate')
  end

  it 'does fix the broken object lookup' do
    migrate
    expect(ObjectLookup.by_name('SMIMECertificate')).not_to be_nil
  end
end
