// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { Organization } from '#shared/graphql/types.ts'

import {
  openOrganizationEditFlyout,
  useOrganizationEdit,
} from '#desktop/entities/organization/composables/useOrganizationEdit.ts'
import type { DetailViewActionPlugin } from '#desktop/types/actions.ts'

export default <DetailViewActionPlugin>{
  key: 'edit-organization',
  label: __('Edit'),
  icon: 'pencil',
  order: 100,
  permission: ['ticket.agent', 'admin.organization'],
  show: (organization?: Organization) => organization?.policy.update,
  initialize: useOrganizationEdit,
  onClick: (organization?: Organization) => {
    if (!organization) return

    openOrganizationEditFlyout(organization)
  },
}
