<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonEmptyMessage from '#desktop/components/CommonEmptyMessage/CommonEmptyMessage.vue'

defineEmits<{
  'open-settings': []
}>()
</script>

<template>
  <CommonEmptyMessage
    class="absolute top-1/2 w-full -translate-y-1/2 text-center ltr:left-1/2 ltr:-translate-x-1/2 rtl:right-1/2 rtl:translate-x-1/2"
    :title="$t('No subscribed chat topics')"
    icon="chat"
  >
    <div class="flex flex-col items-center gap-2.5 py-5">
      <div>
        <CommonLabel tag="p" class="block!">
          {{ $t("Seems like you haven't turned on any of the chat topics yet?") }}
        </CommonLabel>
        <CommonLabel tag="p" class="block!">
          {{
            $t(
              'You need to subscribe to at least one topic in the settings to enable chat availability.',
            )
          }}
        </CommonLabel>
      </div>

      <CommonButton
        variant="tertiary"
        size="small"
        prefix-icon="gear"
        @click="$emit('open-settings')"
      >
        {{ $t('Settings') }}
      </CommonButton>
    </div>
  </CommonEmptyMessage>
</template>
