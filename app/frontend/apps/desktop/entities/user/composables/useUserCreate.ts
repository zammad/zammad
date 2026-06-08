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
import { useFieldOrganizationOption } from '#desktop/components/Form/fields/FieldOrganization/useFieldOrganizationOption.ts'

const USER_CREATE_FLYOUT_NAME = 'user-create-flyout'

const { buildUserSchema } = useUserFormSchema()

const userCreateFormSchema = defineFormSchema([
  {
    isLayout: true,
    component: 'FormGroup',
    children: buildUserSchema('create'),
  },
])

const buildUserEditFormChangeFields = (organization?: Organization) => {
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
      initialValue: organization?.internalId,
      props: {
        options: organization ? [useFieldOrganizationOption(organization)] : [],
      },
    },
  } satisfies Record<string, Partial<FormSchemaField>>
}

export const openUserCreateFlyout = async (options?: {
  title?: string
  organization?: Organization
  onSuccess?: (data: unknown) => void
}) => {
  const formChangeFields = buildUserEditFormChangeFields(options?.organization)

  return openFlyout(USER_CREATE_FLYOUT_NAME, {
    name: USER_CREATE_FLYOUT_NAME,
    title: options?.title ?? __('New user'),
    icon: 'user',
    type: EnumObjectManagerObjects.User,
    mutation: useUserAddMutation,
    schema: userCreateFormSchema,
    formChangeFields,
    formUpdaterId: EnumFormUpdaterId.FormUpdaterUpdaterUserEdit,
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
