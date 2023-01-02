// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { reactive } from 'vue'
import { useDialogObjectForm } from '@mobile/components/CommonDialogObjectForm/useDialogObjectForm'
import { defineFormSchema } from '@mobile/form/defineFormSchema'
import type { OrganizationQuery } from '@shared/graphql/types'
import type { FormSchemaField } from '@shared/components/Form/types'
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

  const schema = defineFormSchema(
    [
      {
        name: 'name',
        required: true,
        screen: 'edit',
        object: EnumObjectManagerObjects.Organization,
      },
      {
        screen: 'edit',
        object: EnumObjectManagerObjects.Organization,
      },
      {
        name: 'active',
        required: true,
        screen: 'edit',
        object: EnumObjectManagerObjects.Organization,
      },
      {
        type: 'file',
        name: 'attachments',
      },
    ],
    { showDirtyMark: true },
  )

  const openEditOrganizationDialog = async (
    organization: ConfidentTake<OrganizationQuery, 'organization'>,
  ) => {
    const formChangeFields = reactive<Record<string, Partial<FormSchemaField>>>(
      {
        domain: {
          required: !!organization.domainAssignment,
        },
      },
    )

    dialog.openDialog({
      object: organization,
      schema,
      mutation: useOrganizationUpdateMutation,
      formChangeFields,
      onChangedField: (fieldName, newValue) => {
        if (fieldName === 'domain_assignment') {
          // TODO: Can be changed when we have the new toggle field (currently the value can also be a string).
          formChangeFields.domain.required =
            (typeof newValue === 'boolean' && newValue) || newValue === 'true'
        }
      },
      formUpdaterId: EnumFormUpdaterId.FormUpdaterUpdaterOrganizationEdit,
      errorNotificationMessage: __('Organization could not be updated.'),
    })
  }

  return { openEditOrganizationDialog }
}
