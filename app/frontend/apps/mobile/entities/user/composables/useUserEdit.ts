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

  const openEditUserDialog = async (user: ConfidentTake<UserQuery, 'user'>) => {
    dialog.openDialog({
      object: user,
      mutation: useUserUpdateMutation,
      schema,
      formChangeFields,
      formUpdaterId: EnumFormUpdaterId.FormUpdaterUpdaterUserEdit,
      errorNotificationMessage: __('User could not be updated.'),
    })
  }

  return { openEditUserDialog }
}
