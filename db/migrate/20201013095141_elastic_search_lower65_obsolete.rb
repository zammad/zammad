# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ElasticSearchLower65Obsolete < ActiveRecord::Migration[5.2]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.find_by(name: 'es_multi_index').destroy
  end
end
