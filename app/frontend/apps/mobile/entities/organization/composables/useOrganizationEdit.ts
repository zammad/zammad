// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { useDialog } from '@shared/composables/useDialog'
import type { OrganizationQuery } from '@shared/graphql/types'
import type { ConfidentTake } from '@shared/types/utils'

export const useOrganizationEdit = () => {
  const editDialog = useDialog({
    name: 'organization-edit',
    component: () =>
      import('@mobile/components/Organization/OrganizationEditDialog.vue'),
  })

  const openEditOrganizationDialog = async (
    organization: ConfidentTake<OrganizationQuery, 'organization'>,
  ) => {
    editDialog.open({
      organization,
      name: editDialog.name,
    })
  }

  return { openEditOrganizationDialog }
}
