<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import Form from '#shared/components/Form/Form.vue'
import { defineFormSchema } from '#shared/form/defineFormSchema.ts'

import CommonDialog from '#desktop/components/CommonDialog/CommonDialog.vue'
import CommonDialogActionFooter from '#desktop/components/CommonDialog/CommonDialogActionFooter.vue'

import { handleFeedbackConsent } from './composables/useBetaUiFeedbackConsent.ts'

const dummySchema = defineFormSchema([
  {
    name: 'rating',
    label: __('You were using the new BETA UI for 5 hours.'),
    type: 'rating',
    required: true,
    disabled: true,
  },
  {
    name: 'comment',
    label: __('Comment'),
    type: 'text',
    required: true,
    disabled: true,
  },
])
</script>

<template>
  <CommonDialog
    name="beta-ui-feedback-consent"
    class="flex max-w-2xl flex-col gap-6 text-start"
    :header-title="__('Want to join the BETA UI feedback program?')"
    wrapper-tag="article"
    no-close
    global
    fullscreen
  >
    <div
      class="flex h-46 items-end justify-center rounded-sm border border-neutral-100 bg-yellow-500 dark:border-gray-900"
    >
      <img
        class="dark:hidden"
        src="./assets/beta-ui-illustration-light.svg"
        :alt="$t('BETA UI illustration')"
      />
      <img
        class="hidden dark:block"
        src="./assets/beta-ui-illustration-dark.svg"
        :alt="$t('BETA UI illustration')"
      />
    </div>
    <CommonLabel>
      {{
        $t(
          'Hey, we have something to show you! Our team has been working on the new Zammad UI for a while, and we’re very eager for you to try it and send some feedback. It involves asking you to rate your experience and provide an optional comment every once in a while.',
        )
      }}
    </CommonLabel>
    <div
      class="flex justify-center gap-3 rounded-sm border border-neutral-100 bg-blue-200 p-3 dark:border-gray-900 dark:bg-gray-700"
    >
      <div class="basis-full">
        <CommonLabel class="text-black dark:text-white">
          {{ $t('The data we need to collect consists of:') }}
        </CommonLabel>
        <ul class="list-disc ps-6 text-gray-100 dark:text-neutral-400">
          <li>
            <CommonLabel>
              {{
                $t(
                  'anonymized rating and comment on the new UI, repeated in a few timely iterations',
                )
              }}
            </CommonLabel>
          </li>
          <li>
            <CommonLabel>
              {{ $t('anonymized tracked usage time of the new UI') }}
            </CommonLabel>
          </li>
          <li>
            <CommonLabel>
              {{ $t('name of the Zammad instance with tracked usage time of the new UI.') }}
            </CommonLabel>
          </li>
        </ul>
      </div>
      <div class="basis-full">
        <div
          class="rounded-sm border border-neutral-100 bg-neutral-50 p-3 dark:border-gray-900 dark:bg-gray-500"
        >
          <Form :schema="dummySchema" />
        </div>
      </div>
    </div>
    <CommonLabel>
      {{ $t('Help us shape the future of Zammad!') }}
    </CommonLabel>
    <template #footer>
      <CommonDialogActionFooter
        :action-label="__('Agree & join')"
        :cancel-label="__('Maybe later')"
        @cancel="handleFeedbackConsent(false)"
        @action="handleFeedbackConsent(true)"
      />
    </template>
  </CommonDialog>
</template>
