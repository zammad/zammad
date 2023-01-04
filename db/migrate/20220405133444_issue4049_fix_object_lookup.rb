# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue4049FixObjectLookup < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    ObjectLookup.find_by(name: 'SmimeCertificate')&.update(name: 'SMIMECertificate')
  end
end
