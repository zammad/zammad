// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { useDialogObjectForm } from '#mobile/components/CommonDialogObjectForm/useDialogObjectForm.ts'
import { defineFormSchema } from '#mobile/form/defineFormSchema.ts'
import { useUserUpdateMutation } from '#mobile/pages/user/graphql/mutations/update.api.ts'
import type { FormSchemaField } from '#shared/components/Form/types.ts'
import type { UserQuery } from '#shared/graphql/types.ts'
import {
  EnumFormUpdaterId,
  EnumObjectManagerObjects,
} from '#shared/graphql/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import type { ConfidentTake } from '#shared/types/utils.ts'

export const useUserEdit = () => {
  const dialog = useDialogObjectForm('user-edit', EnumObjectManagerObjects.User)

  const schema = defineFormSchema(
    [
      {
        screen: 'edit',
        object: EnumObjectManagerObjects.User,
      },
      {
        name: 'active',
        required: true,
        screen: 'edit',
        object: EnumObjectManagerObjects.User,
      },
    ],
    { showDirtyMark: true },
  )

  const application = useApplicationStore()

  const openEditUserDialog = async (user: ConfidentTake<UserQuery, 'user'>) => {
    const formChangeFields: Record<string, Partial<FormSchemaField>> = {
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
    }

    dialog.openDialog({
      object: user,
      mutation: useUserUpdateMutation,
      schema,
      formChangeFields,
      onChangedField: (fieldName, newValue) => {
        if (
          fieldName === 'organization_id' &&
          application.config.ticket_organization_reassignment
        ) {
          formChangeFields.organization_id ||= {}

          let msg = __(
            "Attention! Changing the organization will update the user's most recent tickets to the new organization.",
          )
          let helpClass = 'text-yellow'

          if (user.organization?.internalId === newValue) {
            msg = ''
            helpClass = ''
          }

          formChangeFields.organization_id.help = msg

          // TODO: helpClass is not reactive right now, should be fine with a future FormKit version
          formChangeFields.organization_id.helpClass = helpClass
        }
      },
      formUpdaterId: EnumFormUpdaterId.FormUpdaterUpdaterUserEdit,
      errorNotificationMessage: __('User could not be updated.'),
    })
  }

  return { openEditUserDialog }
}
