// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FormSchemaField } from '#shared/components/Form/types.ts'
import { useUserFormSchema } from '#shared/entities/user/composables/useUserFormSchema.ts'
import { useUserUpdateMutation } from '#shared/entities/user/graphql/mutations/update.api.ts'
import { defineFormSchema } from '#shared/form/defineFormSchema.ts'
import type { UserQuery } from '#shared/graphql/types.ts'
import { EnumFormUpdaterId, EnumObjectManagerObjects } from '#shared/graphql/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import type { ConfidentTake } from '#shared/types/utils.ts'

import { openFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import { useFlyoutObjectForm } from '#desktop/components/CommonFlyoutObjectForm/useFlyoutObjectForm.ts'

const USER_EDIT_FLYOUT_NAME = 'user-edit-flyout'

const { buildUserSchema } = useUserFormSchema()

const userEditFormSchema = defineFormSchema([
  {
    isLayout: true,
    component: 'FormGroup',
    children: buildUserSchema('edit'),
  },
])

const buildUserEditFormChangeFields = (): Record<string, Partial<FormSchemaField>> => {
  const noteMetaDisabled = {
    mentionText: {
      disabled: true,
    },
    mentionKnowledgeBase: {
      disabled: true,
    },
    mentionUser: {
      disabled: true,
    },
  }

  return {
    note: {
      props: {
        meta: noteMetaDisabled,
      },
    },
    organization_id: {
      helpClass: '',
    },
  }
}

export const openUserEditFlyout = async (
  user: ConfidentTake<UserQuery, 'user'>,
  options?: { title: string },
) => {
  const application = useApplicationStore()

  const formChangeFields = buildUserEditFormChangeFields()

  return openFlyout(USER_EDIT_FLYOUT_NAME, {
    name: USER_EDIT_FLYOUT_NAME,
    title: options?.title ?? __('Edit user'),
    icon: 'user',
    type: EnumObjectManagerObjects.User,
    object: user,
    mutation: useUserUpdateMutation,
    schema: userEditFormSchema,
    formChangeFields,
    formUpdaterId: EnumFormUpdaterId.FormUpdaterUpdaterUserEdit,
    onChangedField: (fieldName: string, newValue: number) => {
      if (fieldName !== 'organization_id' || !application.config.ticket_organization_reassignment)
        return

      formChangeFields.organization_id ||= {}

      let help = __(
        "Attention! Changing the organization will update the user's most recent tickets to the new organization.",
      )
      let helpClass = 'text-yellow'

      if (user.organization?.internalId === newValue) {
        help = ''
        helpClass = ''
      }

      formChangeFields.organization_id.help = help
      formChangeFields.organization_id.helpClass = helpClass
    },
    errorNotificationMessage: __('User could not be updated.'),
  })
}

export const useUserEdit = () => {
  useFlyoutObjectForm(USER_EDIT_FLYOUT_NAME, EnumObjectManagerObjects.User)

  return { openUserEditFlyout }
}
