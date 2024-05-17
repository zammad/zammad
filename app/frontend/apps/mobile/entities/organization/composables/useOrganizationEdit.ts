// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { reactive } from 'vue'

import type { FormSchemaField } from '#shared/components/Form/types.ts'
import { defineFormSchema } from '#shared/form/defineFormSchema.ts'
import type { OrganizationQuery } from '#shared/graphql/types.ts'
import {
  EnumFormUpdaterId,
  EnumObjectManagerObjects,
} from '#shared/graphql/types.ts'
import type { ConfidentTake } from '#shared/types/utils.ts'

import { useDialogObjectForm } from '#mobile/components/CommonDialogObjectForm/useDialogObjectForm.ts'

import { useOrganizationUpdateMutation } from '../graphql/mutations/update.api.ts'

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
        note: {
          props: {
            meta: {
              mentionText: {
                disabled: true,
              },
              mentionKnowledgeBase: {
                disabled: true,
              },
              mentionUser: {
                disabled: true,
              },
            },
          },
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
