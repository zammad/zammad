# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class ApplicationModel < ActiveRecord::Base
  include ApplicationModel::ActivityStreamLoggable
  include ApplicationModel::Cacheable
  include ApplicationModel::CanLookup
  include ApplicationModel::CanLookupSearchIndexAttributes
  include ApplicationModel::ChecksAttributeValuesAndLength
  include ApplicationModel::CleansParam
  include ApplicationModel::CleansRecentView
  include ApplicationModel::FillsByUserColumns
  include ApplicationModel::HandlesCreatesAndUpdates
  include ApplicationModel::HasAssets
  include ApplicationModel::HasAssociations
  include ApplicationModel::HasAttachments
  include ApplicationModel::HasLatestChangeTimestamp
  include ApplicationModel::HasExternalSync
  include ApplicationModel::Importable
  include ApplicationModel::HistoryLoggable
  include ApplicationModel::TouchesReferences

  self.abstract_class = true
end
