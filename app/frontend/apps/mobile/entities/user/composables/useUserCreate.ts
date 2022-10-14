// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { useDialogObjectForm } from '@mobile/components/CommonDialogObjectForm/useDialogObjectForm'
import { defineFormSchema } from '@mobile/form/composable'
import { useUserAddMutation } from '@mobile/pages/user/graphql/mutations/add.api'
import type { User, UserAddPayload } from '@shared/graphql/types'
import {
  EnumFormUpdaterId,
  EnumObjectManagerObjects,
} from '@shared/graphql/types'
import { useRouter } from 'vue-router'

export const useUserCreate = () => {
  const dialogCreate = useDialogObjectForm(
    'user-create',
    EnumObjectManagerObjects.User,
  )

  const mutation = useUserAddMutation({})
  const schema = defineFormSchema([
    {
      screen: 'create',
      object: EnumObjectManagerObjects.User,
    },
    {
      name: 'active',
      required: true,
      object: EnumObjectManagerObjects.User,
    },
  ])

  const router = useRouter()

  const onSuccess = (data: { userAdd: UserAddPayload }) => {
    const { internalId } = data.userAdd.user as User

    // TODO change when actually implemented
    router.push(`/users/${internalId}`)
  }

  const openCreateUserDialog = async () => {
    dialogCreate.openDialog({
      mutation,
      schema,
      onSuccess,
      formUpdaterId: EnumFormUpdaterId.FormUpdaterUpdaterUserAdd,
      errorNotificationMessage: __('User could not be created.'),
    })
  }

  return { openCreateUserDialog }
}
