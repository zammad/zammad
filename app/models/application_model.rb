# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ApplicationModel < ActiveRecord::Base
  include ActiveModel::Validations

  include ApplicationModel::CanActivityStreamLog
  include ApplicationModel::HasCache
  include ApplicationModel::CanLookup
  include ApplicationModel::CanLookupSearchIndexAttributes
  include ApplicationModel::ChecksAttributeValuesAndLength
  include ApplicationModel::CanCleanupParam
  include ApplicationModel::HasRecentViews
  include ApplicationModel::ChecksUserColumnsFillup
  include ApplicationModel::CanCreatesAndUpdates
  include ApplicationModel::CanAssets
  include ApplicationModel::CanAssociations
  include ApplicationModel::HasAttachments
  include ApplicationModel::CanLatestChange
  include ApplicationModel::HasExternalSync
  include ApplicationModel::ChecksImport
  include ApplicationModel::CanTouchReferences
  include ApplicationModel::CanQueryCaseInsensitiveWhereOrSql
  include ApplicationModel::HasExistsCheckByObjectAndId

  self.abstract_class = true
end
