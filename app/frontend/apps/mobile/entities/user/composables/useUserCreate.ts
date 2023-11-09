// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { useDialogObjectForm } from '#mobile/components/CommonDialogObjectForm/useDialogObjectForm.ts'
import { defineFormSchema } from '#mobile/form/defineFormSchema.ts'
import { useUserAddMutation } from '#mobile/pages/user/graphql/mutations/add.api.ts'
import type { User, UserAddPayload } from '#shared/graphql/types.ts'
import {
  EnumFormUpdaterId,
  EnumObjectManagerObjects,
} from '#shared/graphql/types.ts'
import { useRouter } from 'vue-router'

interface UserCreateOptions {
  onUserCreated?: (user: User) => void
}

export const useUserCreate = (options: UserCreateOptions = {}) => {
  const dialogCreate = useDialogObjectForm(
    'user-create',
    EnumObjectManagerObjects.User,
  )

  const schema = defineFormSchema([
    {
      screen: 'create',
      object: EnumObjectManagerObjects.User,
    },
    {
      name: 'active',
      required: true,
      screen: 'create',
      object: EnumObjectManagerObjects.User,
    },
  ])

  const router = useRouter()

  const onSuccess = (data: { userAdd: UserAddPayload }) => {
    const { internalId } = data.userAdd.user as User

    router.push(`/users/${internalId}`)
  }

  const openCreateUserDialog = async () => {
    dialogCreate.openDialog({
      mutation: useUserAddMutation,
      schema,
      onSuccess: options.onUserCreated
        ? (query: { userAdd: UserAddPayload }) =>
            options.onUserCreated!(query.userAdd.user!)
        : onSuccess,
      formUpdaterId: EnumFormUpdaterId.FormUpdaterUpdaterUserCreate,
      errorNotificationMessage: __('User could not be created.'),
    })
  }

  return { openCreateUserDialog }
}
