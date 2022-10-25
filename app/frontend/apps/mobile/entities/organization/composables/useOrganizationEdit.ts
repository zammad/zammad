// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { useDialogObjectForm } from '@mobile/components/CommonDialogObjectForm/useDialogObjectForm'
import { defineFormSchema } from '@mobile/form/defineFormSchema'
import type { OrganizationQuery } from '@shared/graphql/types'
import {
  EnumFormUpdaterId,
  EnumObjectManagerObjects,
} from '@shared/graphql/types'
import type { ConfidentTake } from '@shared/types/utils'
import { useOrganizationUpdateMutation } from '../graphql/mutations/update.api'

export const useOrganizationEdit = () => {
  const dialog = useDialogObjectForm(
    'organization-edit',
    EnumObjectManagerObjects.Organization,
  )

  const mutation = useOrganizationUpdateMutation({})
  const schema = defineFormSchema([
    {
      name: 'name',
      required: true,
      object: EnumObjectManagerObjects.Organization,
    },
    {
      screen: 'edit',
      object: EnumObjectManagerObjects.Organization,
    },
    {
      name: 'active',
      required: true,
      object: EnumObjectManagerObjects.Organization,
    },
  ])

  const openEditOrganizationDialog = async (
    organization: ConfidentTake<OrganizationQuery, 'organization'>,
  ) => {
    dialog.openDialog({
      object: organization,
      schema,
      mutation,
      formUpdaterId: EnumFormUpdaterId.FormUpdaterUpdaterOrganizationEdit,
      errorNotificationMessage: __('Organization could not be updated.'),
    })
  }

  return { openEditOrganizationDialog }
}
