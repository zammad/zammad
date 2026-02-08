<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { FormKit } from '@formkit/vue'

import { useConfirmation } from '#shared/composables/useConfirmation.ts'

import { useBetaUi } from '#desktop/components/BetaUi/composables/useBetaUi.ts'
import {
  showFeedbackConsent,
  handleFeedbackConsent,
} from '#desktop/components/BetaUi/composables/useBetaUiFeedbackConsent.ts'
import { useFeedbackDialog } from '#desktop/components/BetaUi/FeedbackDialog/useFeedbackDialog.ts'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import { useAppUsage } from '#desktop/composables/BetaUi/useAppUsage.ts'

import { useBreadcrumb } from '../composables/useBreadcrumb.ts'

const { breadcrumbItems } = useBreadcrumb(__('New BETA UI'))

const {
  toggleBetaUiSwitch,
  switchValue,
  toggleDismissBetaUiSwitch,
  dismissValue,
  hasFeedbackConsent,
} = useBetaUi()

const { openFeedbackDialog } = useFeedbackDialog()

const { waitForConfirmation } = useConfirmation()

const { setNeverAskAgainForTimedFeedback, neverAskAgainForTimedFeedback } = useAppUsage()

const leaveFeedbackProgram = () => {
  waitForConfirmation(__('You can always re-join later.'), {
    buttonVariant: 'danger',
    buttonLabel: __('Leave program'),
    headerTitle: __('Leave BETA UI feedback program?'),
  }).then((confirmed) => {
    if (confirmed) handleFeedbackConsent(false)
  })
}
</script>

<template>
  <LayoutContent :breadcrumb-items="breadcrumbItems" width="full">
    <div class="mb-2 flex flex-col gap-4">
      <FormKit
        type="toggle"
        :label="__('Display Zammad with the new BETA user interface')"
        :value="true"
        :variants="{ true: 'True', false: 'False' }"
        @input-raw="toggleBetaUiSwitch()"
      />

      <FormKit
        type="checkbox"
        :model-value="!dismissValue"
        :label="__('Show the BETA switch between the old and the new UI in the primary navigation')"
        :aria-label="
          dismissValue
            ? $t('Disable the banner for the BETA switch')
            : $t('Enable the banner for the BETA switch')
        "
        name="toggle-dismiss-beta-ui-switch"
        @click="toggleDismissBetaUiSwitch"
      />

      <template v-if="switchValue">
        <CommonLabel class="mt-2" size="large" tag="h2">{{
          $t('BETA UI feedback program')
        }}</CommonLabel>

        <div v-if="hasFeedbackConsent === 'true'" class="flex gap-4">
          <CommonLabel tag="p">
            {{ $t('You are part of the BETA UI feedback program.') }}
          </CommonLabel>
          <CommonButton variant="tertiary" @click="leaveFeedbackProgram()">
            {{ $t('Leave program') }}</CommonButton
          >
        </div>

        <FormKit
          v-if="hasFeedbackConsent === 'true'"
          type="checkbox"
          :label="__('Do not ask automatically for feedback on the BETA UI')"
          name="toggle-dismiss-beta-ui-switch"
          :model-value="neverAskAgainForTimedFeedback"
          @update:model-value="setNeverAskAgainForTimedFeedback"
        />

        <div class="flex gap-4">
          <CommonButton
            v-if="hasFeedbackConsent === 'true'"
            variant="primary"
            @click="openFeedbackDialog()"
          >
            {{ $t('Give feedback') }}
          </CommonButton>
          <template v-else>
            <CommonLabel tag="p">
              {{ $t('Would you like to give us feedback on the BETA UI? ') }}
            </CommonLabel>
            <CommonButton @click="showFeedbackConsent">{{
              $t('Join feedback program')
            }}</CommonButton>
          </template>
        </div>
      </template>
    </div>
  </LayoutContent>
</template>
