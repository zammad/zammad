<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { FormValues } from '#shared/components/Form/types.ts'
import { useMacros } from '#shared/entities/macro/composables/useMacros.ts'
import type { MacroById } from '#shared/entities/macro/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

export interface Props {
  dirty: boolean
  disabled: boolean
  formNodeId?: string
  canUpdateTicket: boolean
  formValues: FormValues
}

const props = defineProps<Props>()

const emit = defineEmits<{
  submit: [MouseEvent]
  discard: [MouseEvent]
  'execute-macro': [MacroById]
}>()

const groupId = computed(() =>
  props.formValues.group_id
    ? convertToGraphQLId('Group', props.formValues.group_id as number)
    : undefined,
)
const { macros } = useMacros(groupId)

const groupLabels = {
  drafts: __('Drafts'),
  macros: __('Macros'),
}

const actionItems = computed(() => {
  if (!macros.value) return null

  const macroMenu = macros.value.map((macro) => ({
    key: macro.id,
    label: macro.name,
    groupLabel: groupLabels.macros,
    onClick: () => emit('execute-macro', macro),
  }))

  return [
    // :TODO add later drafts action item
    // {
    //   label: __('Save as draft'),
    //   groupLabel: groupLabels.drafts,
    //   icon: 'floppy',
    //   key: 'macro1',
    //   onClick: () => {},
    // },
    ...(groupId.value ? macroMenu : []),
  ]
})
</script>

<template>
  <!--  Add live user handling-->
  <!--  <div class="ltr:mr-auto rtl:ml-auto">live user -> COMPONENT</div>-->
  <template v-if="canUpdateTicket">
    <CommonButton
      v-if="dirty"
      size="large"
      variant="danger"
      :disabled="disabled"
      @click="$emit('discard', $event)"
      >{{ $t('Discard your unsaved changes') }}</CommonButton
    >
    <CommonButton
      size="large"
      variant="submit"
      type="button"
      :form="formNodeId"
      :disabled="disabled"
      @click="$emit('submit', $event)"
      >{{ $t('Update') }}</CommonButton
    >
    <CommonActionMenu
      v-if="actionItems"
      no-single-action-mode
      placement="arrowEnd"
      :actions="actionItems"
    />
  </template>
</template>
