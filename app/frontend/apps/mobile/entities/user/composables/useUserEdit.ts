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
import { edgesToArray } from '@shared/utils/helpers'

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
    const transformedUserObject = {
      ...user,
      // TODO: Currently we have no autocomplete prefill functionality (maybe with formUpdater?)
      // TODO: Also we have not always the full set on secondary organization in the frontend (currently also a bug in the desktop view).
      organization_id: user.organization?.internalId,
      organization_ids: edgesToArray(user.secondaryOrganizations).map(
        (item) => item.internalId,
      ),
    }

    delete transformedUserObject.organization
    delete transformedUserObject.secondaryOrganizations

    dialog.openDialog({
      object: transformedUserObject,
      mutation,
      schema,
      formUpdaterId: EnumFormUpdaterId.FormUpdaterUpdaterUserEdit,
      errorNotificationMessage: __('User could not be updated.'),
    })
  }

  return { openEditUserDialog }
}
