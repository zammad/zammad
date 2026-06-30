// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FormSchemaField } from '#shared/components/Form/types.ts'
import { useOrganizationFormSchema } from '#shared/entities/organization/composables/useOrganizationFormSchema.ts'
import { useOrganizationUpdateMutation } from '#shared/entities/organization/graphql/mutations/update.api.ts'
import type { EditableOrganization } from '#shared/entities/organization/types.ts'
import { defineFormSchema } from '#shared/form/defineFormSchema.ts'
import { EnumFormUpdaterId, EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { openFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import { useFlyoutObjectForm } from '#desktop/components/CommonFlyoutObjectForm/useFlyoutObjectForm.ts'

const ORGANIZATION_EDIT_FLYOUT_NAME = 'organization-edit-flyout'

const { buildOrganizationSchema } = useOrganizationFormSchema()

const organizationEditFormSchema = defineFormSchema([
  {
    isLayout: true,
    component: 'FormGroup',
    children: buildOrganizationSchema('edit'),
  },
])

const buildOrganizationEditFormChangeFields = (): Record<string, Partial<FormSchemaField>> => {
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
  }
}

export const openOrganizationEditFlyout = async (
  organization: EditableOrganization,
  options?: { title: string },
) => {
  const formChangeFields = buildOrganizationEditFormChangeFields()

  return openFlyout(ORGANIZATION_EDIT_FLYOUT_NAME, {
    name: ORGANIZATION_EDIT_FLYOUT_NAME,
    title: options?.title ?? __('Edit organization'),
    icon: 'buildings',
    type: EnumObjectManagerObjects.Organization,
    object: organization,
    mutation: useOrganizationUpdateMutation,
    schema: organizationEditFormSchema,
    formChangeFields,
    formUpdaterId: EnumFormUpdaterId.FormUpdaterUpdaterOrganizationEdit,
    errorNotificationMessage: __('Organization could not be updated.'),
  })
}

export const useOrganizationEdit = () => {
  useFlyoutObjectForm(ORGANIZATION_EDIT_FLYOUT_NAME, EnumObjectManagerObjects.Organization)

  return { openOrganizationEditFlyout }
}
