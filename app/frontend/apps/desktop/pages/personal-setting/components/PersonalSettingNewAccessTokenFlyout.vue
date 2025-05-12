<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref } from 'vue'

import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { useUserCurrentAccessTokenAddMutation } from '#shared/entities/user/current/graphql/mutations/userCurrentAccessTokenAdd.api.ts'
import { UserCurrentAccessTokenListDocument } from '#shared/entities/user/current/graphql/queries/userCurrentAcessTokenList.api.ts'
import { defineFormSchema } from '#shared/form/defineFormSchema.ts'
import {
  EnumFormUpdaterId,
  type UserCurrentAccessTokenListQuery,
} from '#shared/graphql/types.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'

import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'
import type { ActionFooterOptions } from '#desktop/components/CommonFlyout/types.ts'
import { closeFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import CommonInputCopyToClipboard from '#desktop/components/CommonInputCopyToClipboard/CommonInputCopyToClipboard.vue'

import type { NewTokenAccessFormData } from '../types/token-access.ts'

const { form } = useForm()

const formSchema = defineFormSchema([
  {
    type: 'text',
    name: 'name',
    label: __('Name'),
    required: true,
  },
  {
    type: 'date',
    name: 'expires_at',
    label: __('Expiration date'),
    props: {
      futureOnly: true,
    },
  },
  {
    type: 'permissions',
    name: 'permissions',
    label: 'Permissions',
    props: {
      options: [],
    },
    required: true,
  },
])

const accessTokenCreateMutation = new MutationHandler(
  useUserCurrentAccessTokenAddMutation({
    update: (cache, { data }) => {
      if (!data) return

      const { userCurrentAccessTokenAdd } = data
      if (!userCurrentAccessTokenAdd?.token) return

      let existingAccessTokens =
        cache.readQuery<UserCurrentAccessTokenListQuery>({
          query: UserCurrentAccessTokenListDocument,
        })

      const newIdPresent =
        existingAccessTokens?.userCurrentAccessTokenList?.find((token) => {
          return token.id === userCurrentAccessTokenAdd.token?.id
        })
      if (newIdPresent) return

      existingAccessTokens = {
        ...existingAccessTokens,
        userCurrentAccessTokenList: [
          userCurrentAccessTokenAdd.token,
          ...(existingAccessTokens?.userCurrentAccessTokenList || []),
        ],
      }

      cache.writeQuery({
        query: UserCurrentAccessTokenListDocument,
        data: existingAccessTokens,
      })
    },
  }),
  {
    errorNotificationMessage: __('The access token could not be created.'),
  },
)

const accessToken = ref<string>('')

const submitForm = (data: FormSubmitData<NewTokenAccessFormData>) => {
  return accessTokenCreateMutation
    .send({
      input: {
        name: data.name,
        expiresAt: data.expires_at,
        permission: data.permissions,
      },
    })
    .then((result) => {
      if (result?.userCurrentAccessTokenAdd?.tokenValue) {
        accessToken.value = result.userCurrentAccessTokenAdd.tokenValue
      }
    })
}

const footerActionOptions = computed<ActionFooterOptions>(() => {
  if (accessToken.value) {
    return {
      actionLabel: __('OK, I have copied my token'),
      actionButton: { variant: 'primary' },
      hideCancelButton: true,
    }
  }

  return {
    actionLabel: __('Create'),
    actionButton: { variant: 'submit', type: 'submit' },
  }
})

const actionCloseFlyout = () => {
  if (accessToken.value) closeFlyout('new-access-token')
}
</script>

<template>
  <CommonFlyout
    :header-title="__('New Personal Access Token')"
    :form="form"
    :footer-action-options="footerActionOptions"
    header-icon="key"
    no-close-on-action
    name="new-access-token"
    @action="actionCloseFlyout()"
    @activated="form?.triggerFormUpdater"
  >
    <div v-if="accessToken" class="flex flex-col gap-3">
      <CommonLabel>{{
        $t(
          "For security reasons, the API token is shown only once. You'll need to save it somewhere secure before continuing.",
        )
      }}</CommonLabel>
      <CommonInputCopyToClipboard
        :value="accessToken"
        :label="__('Your Personal Access Token')"
        :copy-button-text="__('Copy Token')"
      />
    </div>
    <Form
      v-else
      ref="form"
      :schema="formSchema"
      :form-updater-id="
        EnumFormUpdaterId.FormUpdaterUpdaterUserCurrentNewAccessToken
      "
      form-updater-initial-only
      should-autofocus
      @submit="submitForm($event as FormSubmitData<NewTokenAccessFormData>)"
    />
  </CommonFlyout>
</template>
