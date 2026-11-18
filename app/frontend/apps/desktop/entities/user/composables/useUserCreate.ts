// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FormSchemaField } from '#shared/components/Form/types.ts'
import { useUserFormSchema } from '#shared/entities/user/composables/useUserFormSchema.ts'
import { useUserAddMutation } from '#shared/entities/user/graphql/mutations/add.api.ts'
import { defineFormSchema } from '#shared/form/defineFormSchema.ts'
import {
  EnumFormUpdaterId,
  EnumObjectManagerObjects,
  type Organization,
} from '#shared/graphql/types.ts'

import { openFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import { useFlyoutObjectForm } from '#desktop/components/CommonFlyoutObjectForm/useFlyoutObjectForm.ts'

const USER_CREATE_FLYOUT_NAME = 'user-create-flyout'

const { buildUserSchema } = useUserFormSchema()

const userCreateFormSchema = defineFormSchema([
  {
    isLayout: true,
    component: 'FormGroup',
    children: buildUserSchema('create'),
  },
])

const buildUserCreateFormChangeFields = () => {
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
  } satisfies Record<string, Partial<FormSchemaField>>
}

export const openUserCreateFlyout = async (options?: {
  title?: string
  organization?: Organization
  phone?: string
  onSuccess?: (data: unknown) => void
}) => {
  const formChangeFields = buildUserCreateFormChangeFields()

  return openFlyout(USER_CREATE_FLYOUT_NAME, {
    name: USER_CREATE_FLYOUT_NAME,
    title: options?.title ?? __('New user'),
    icon: 'user',
    type: EnumObjectManagerObjects.User,
    // Prefilled values go in as the initial object: the change fields are merged into every
    //   form updater response, so an organization option there would replace the picked one.
    object: { organization: options?.organization, phone: options?.phone },
    mutation: useUserAddMutation,
    schema: userCreateFormSchema,
    formChangeFields,
    formUpdaterId: EnumFormUpdaterId.FormUpdaterUpdaterUserCreate,
    errorNotificationMessage: __('User could not be created.'),
    footerActionOptions: {
      actionLabel: __('Create'),
    },
    onSuccess: options?.onSuccess,
  })
}

export const useUserCreate = () => {
  useFlyoutObjectForm(USER_CREATE_FLYOUT_NAME, EnumObjectManagerObjects.User)

  return { openUserCreateFlyout }
}
