<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<!-- eslint-disable @typescript-eslint/no-unused-vars -->

<script setup lang="ts">
import Form from '#shared/components/Form/Form.vue'
import { useForm } from '#shared/components/Form/useForm.ts'
import { defineFormSchema } from '#shared/form/defineFormSchema.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useUserAddMutation } from '#shared/entities/user/graphql/mutations/add.api.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import { useObjectAttributes } from '#shared/entities/object-attributes/composables/useObjectAttributes.ts'
import { useObjectAttributeFormData } from '#shared/entities/object-attributes/composables/useObjectAttributeFormData.ts'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import {
  GroupAccess,
  type GroupPermissionReactive,
} from '#desktop/components/Form/fields/FieldGroupPermissions/types.ts'
import type { SelectValue } from '#shared/components/CommonSelect/types.ts'
import {
  EnumObjectManagerObjects,
  EnumFormUpdaterId,
  type UserInput,
} from '#shared/graphql/types.ts'
import { useSystemSetup } from '../../composables/useSystemSetup.ts'
import GuidedSetupActionFooter from '../../components/GuidedSetupActionFooter.vue'

const { setBoxSize, setTitle } = useSystemSetup()

setBoxSize?.('large')
setTitle(__('Invite Colleagues'))

const { form } = useForm()

const { notify } = useNotifications()

const schema = defineFormSchema([
  {
    screen: 'invite_agent',
    object: EnumObjectManagerObjects.User,
  },
])

const transformGroupPermissions = (value: GroupPermissionReactive[]) =>
  value.reduce(
    (groupPermissions, row) => {
      if (!row.groups) return groupPermissions

      groupPermissions.push(
        ...(row.groups as unknown as SelectValue[]).map((groupInternalId) => ({
          groupInternalId,
          accessType: Object.keys(row.groupAccess).reduce((accesses, key) => {
            if (row.groupAccess[key as GroupAccess])
              accesses.push(key as GroupAccess)
            return accesses
          }, [] as GroupAccess[]),
        })),
      )
      return groupPermissions
    },
    [] as {
      groupInternalId: SelectValue
      accessType: GroupAccess[]
    }[],
  )

const { attributesLookup } = useObjectAttributes(EnumObjectManagerObjects.User)

const inviteUser = async (formData: FormSubmitData) => {
  // TODO: Try to move this value transformation into the relevant field.
  if (formData.group_ids) {
    formData.group_ids = transformGroupPermissions(
      formData.group_ids as unknown as GroupPermissionReactive[],
    )
  }

  const { internalObjectAttributeValues, additionalObjectAttributeValues } =
    useObjectAttributeFormData(attributesLookup.value, formData)

  const input: UserInput = {
    ...internalObjectAttributeValues,
    objectAttributeValues: additionalObjectAttributeValues,
  }

  const userAdd = new MutationHandler(useUserAddMutation())

  return userAdd
    .send({
      input,
      sendInvite: true,
    })
    .then(async (result) => {
      if (result?.userAdd?.user) {
        notify({
          type: NotificationTypes.Success,
          message: __('Invitation sent!'),
        })
      }
    })
}
</script>

<template>
  <Form
    id="invite-colleagues"
    ref="form"
    form-class="mb-2.5"
    :schema="schema"
    :form-updater-id="EnumFormUpdaterId.FormUpdaterUpdaterUserInvite"
    use-object-attributes
    clear-values-after-submit
    @submit="inviteUser"
  />
  <GuidedSetupActionFooter
    :form="form"
    :submit-button-text="__('Send Invitation')"
    :continue-button-text="__('Finish Setup')"
    continue-route="/guided-setup/manual/finish"
  />
</template>
