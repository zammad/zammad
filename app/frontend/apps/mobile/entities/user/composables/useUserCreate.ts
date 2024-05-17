// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useRouter } from 'vue-router'

import { useUserAddMutation } from '#shared/entities/user/graphql/mutations/add.api.ts'
import { defineFormSchema } from '#shared/form/defineFormSchema.ts'
import type { User, UserAddPayload } from '#shared/graphql/types.ts'
import {
  EnumFormUpdaterId,
  EnumObjectManagerObjects,
} from '#shared/graphql/types.ts'

import { useDialogObjectForm } from '#mobile/components/CommonDialogObjectForm/useDialogObjectForm.ts'

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
