// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { useDialogObjectForm } from '@mobile/components/CommonDialogObjectForm/useDialogObjectForm'
import { defineFormSchema } from '@mobile/form/defineFormSchema'
import { useUserUpdateMutation } from '@mobile/pages/user/graphql/mutations/update.api'
import type { UserQuery } from '@shared/graphql/types'
import {
  EnumFormUpdaterId,
  EnumObjectManagerObjects,
} from '@shared/graphql/types'
import type { ConfidentTake } from '@shared/types/utils'

export const useUserEdit = () => {
  const dialog = useDialogObjectForm('user-edit', EnumObjectManagerObjects.User)

  const mutation = useUserUpdateMutation({})
  const schema = defineFormSchema([
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
  ])

  const openEditUserDialog = async (user: ConfidentTake<UserQuery, 'user'>) => {
    dialog.openDialog({
      object: user,
      mutation,
      schema,
      formUpdaterId: EnumFormUpdaterId.FormUpdaterUpdaterUserEdit,
      errorNotificationMessage: __('User could not be updated.'),
    })
  }

  return { openEditUserDialog }
}
