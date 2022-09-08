// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { useDialog } from '@shared/composables/useDialog'
import type { UserQuery } from '@shared/graphql/types'
import type { ConfidentTake } from '@shared/types/utils'

export const useUserEdit = () => {
  const editDialog = useDialog({
    name: 'user-edit',
    component: () => import('@mobile/components/User/UserEditDialog.vue'),
  })

  const openEditUserDialog = async (user: ConfidentTake<UserQuery, 'user'>) => {
    editDialog.open({
      user,
      name: editDialog.name,
    })
  }

  return { openEditUserDialog }
}
