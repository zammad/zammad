<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script lang="ts" setup>
import { type Ref, ref } from 'vue'

import type { ChecklistItem } from '#shared/graphql/types.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import ChecklistEmptyTemplates from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarChecklistContent/ChecklistEmptyTemplates.vue'
import ChecklistItems from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarChecklistContent/ChecklistItems.vue'
import ChecklistTemplates from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarChecklistContent/ChecklistTemplates.vue'
import { useTicketChecklist } from '#desktop/pages/ticket/composables/useTicketChecklist.ts'

import TicketSidebarContent from './TicketSidebarContent.vue'

import type { TicketSidebarContentProps } from '../types.ts'

defineOptions({
  name: 'ChecklistContent',
})

defineProps<TicketSidebarContentProps>()

const checklistItemsComponent = ref<InstanceType<typeof ChecklistItems>>()

const {
  addNewItem,
  createNewChecklist,
  removeItem,
  setItemCheckedState,
  editItem,
  updateTitle,
  saveItemsOrder,
  checklist,
  checklistTemplates,
  checklistTitle,
  checklistActions,
  isLoading,
  readOnly,
} = useTicketChecklist(
  checklistItemsComponent as Ref<InstanceType<typeof ChecklistItems>>,
)
</script>

<template>
  <TicketSidebarContent
    :actions="readOnly ? undefined : checklistActions"
    :title="__('Checklist')"
    icon="checklist"
  >
    <CommonLoader :loading="isLoading">
      <div class="flex flex-col gap-3">
        <Transition name="none" mode="out-in">
          <ChecklistItems
            v-if="checklist"
            ref="checklistItemsComponent"
            :no-default-title="!!checklist.name"
            :title="checklistTitle"
            :items="<ChecklistItem[]>checklist?.items"
            :read-only="readOnly"
            @add-item="addNewItem"
            @remove-item="removeItem"
            @set-item-checked="setItemCheckedState"
            @edit-item="editItem"
            @save-order="saveItemsOrder"
            @update-title="updateTitle"
          />
          <CommonButton
            v-else-if="!checklist && !readOnly"
            variant="primary"
            size="medium"
            block
            @click="createNewChecklist()"
          >
            {{ $t('Add Empty Checklist') }}
          </CommonButton>
        </Transition>

        <ChecklistEmptyTemplates
          v-if="!checklist && !checklistTemplates?.length"
        />

        <CommonLabel v-if="!checklist && readOnly">{{
          $t('No checklist added to this ticket yet.')
        }}</CommonLabel>

        <ChecklistTemplates
          v-if="checklistTemplates?.length && !checklist && !readOnly"
          :templates="checklistTemplates"
        />
      </div>
    </CommonLoader>
  </TicketSidebarContent>
</template>
