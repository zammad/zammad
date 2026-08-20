<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import useValue from '#shared/components/Form/composables/useValue.ts'
import { i18n } from '#shared/i18n.ts'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import CommonSimpleTable from '#desktop/components/CommonTable/CommonSimpleTable.vue'
import type { TableItem, TableSimpleHeader } from '#desktop/components/CommonTable/types.ts'

import FieldKnowledgeBasePermissionsSkeleton from './FieldKnowledgeBasePermissionsSkeleton.vue'
import {
  KnowledgeBaseAccess,
  type KnowledgeBasePermissionRow,
  type KnowledgeBasePermissions,
  type KnowledgeBasePermissionsContext,
  type PermissionsTableItem,
} from './types.ts'

const props = defineProps<{
  context: KnowledgeBasePermissionsContext
}>()

const context = toRef(props, 'context')

const { localValue } = useValue<KnowledgeBasePermissions>(context)

// `alignContent` only reaches the cells, and its `text-center` is
//   inert on the `inline-flex` label that `CommonSimpleTable` renders in the header.
const labelClass = 'w-full justify-center!'

const tableHeaders: TableSimpleHeader[] = [
  {
    key: 'role',
    label: __('Role'),
  },
  {
    key: KnowledgeBaseAccess.Editor,
    label: __('Editor'),
    alignContent: 'center',
    labelClass,
  },
  {
    key: KnowledgeBaseAccess.Reader,
    label: __('Reader'),
    alignContent: 'center',
    labelClass,
  },
  {
    key: KnowledgeBaseAccess.None,
    label: __('None'),
    alignContent: 'center',
    labelClass,
  },
]

const isLoading = computed(() => !context.value.permissionRows)

const tableItems = computed<PermissionsTableItem[]>(() =>
  (context.value.permissionRows || []).map(
    ({ roleId, roleName, inheritedAccess, allowedAccesses }: KnowledgeBasePermissionRow) => ({
      id: roleId,
      role: roleName,
      inheritedAccess,
      allowedAccesses,
    }),
  ),
)

// `CommonSimpleTable` hands the row back as a plain `TableItem`, so narrow it here instead
//   of casting at every call site in the template.
const row = (item: TableItem) => item as PermissionsTableItem

const isChecked = (item: TableItem, access: KnowledgeBaseAccess) =>
  localValue.value?.[row(item).id] === access

// The levels a role may not be given here. Offering them anyway would not merely be ignored:
//   the form updater clamps an illegal access to the most restrictive allowed one, so the
//   selection would visibly jump to something the user did not ask for.
const isLocked = (item: TableItem, access: KnowledgeBaseAccess) =>
  !row(item).allowedAccesses?.includes(access)

// A disabled radio with no explanation leaves the user guessing, so say which of the two
//   reasons it is. An inherited `editor`/`none` cannot be overridden at all
//   (KnowledgeBase::PermissionsUpdate), and a role without the editor permission cannot be
//   made an editor no matter what the parent says.
const lockReason = (item: TableItem, access: KnowledgeBaseAccess) => {
  if (!isLocked(item, access)) return undefined

  const { inheritedAccess } = row(item)

  if (inheritedAccess === KnowledgeBaseAccess.Editor)
    return i18n.t('The parent already grants this role editor access.')

  if (inheritedAccess === KnowledgeBaseAccess.None)
    return i18n.t('The parent denies this role access.')

  return i18n.t('This role has no knowledge base editor permission.')
}

// Role names are user data and stay untranslated, like in the legacy dialog.
const cellLabel = (item: TableItem, header: TableSimpleHeader) =>
  `${row(item).role} - ${i18n.t(header.label)}`

const selectAccess = (item: TableItem, access: KnowledgeBaseAccess) => {
  localValue.value = { ...localValue.value, [row(item).id]: access }
}
</script>

<template>
  <output
    :id="context.id"
    :class="context.classes.input"
    :name="context.node.name"
    :aria-disabled="context.disabled"
    :aria-describedby="context.describedBy"
    v-bind="context.attrs"
    role="group"
  >
    <CommonLoader :loading="isLoading">
      <template #skeleton>
        <FieldKnowledgeBasePermissionsSkeleton />
      </template>

      <CommonSimpleTable
        :caption="__('Permissions matrix')"
        class="w-full"
        :headers="tableHeaders"
        :items="tableItems"
      >
        <!-- Radio group membership is by `name`, not by DOM ancestry, so one group per role
        works across the three cells and keyboard behaviour comes for free. -->
        <template
          v-for="access in KnowledgeBaseAccess"
          :key="access"
          #[`column-cell-${access}`]="{ item, header }"
        >
          <!-- The lock reason is `supportive` so it lands in `aria-description`: an `aria-label`
          here would replace the cell label below as the radio's accessible name. -->
          <label
            v-tooltip.supportive="lockReason(item, access)"
            class="group inline-flex size-8 items-center justify-center rounded-full"
            :class="isLocked(item, access) ? 'cursor-not-allowed' : 'cursor-pointer'"
            :for="`kb_permissions_radio_${context.id}_${item.id}_${access}`"
          >
            <input
              :id="`kb_permissions_radio_${context.id}_${item.id}_${access}`"
              type="radio"
              class="peer sr-only"
              :name="`kb_permissions_radio_${context.id}_${item.id}`"
              :value="access"
              :checked="isChecked(item, access)"
              :disabled="context.disabled || isLocked(item, access)"
              @change="selectAccess(item, access)"
              @blur="context.handlers.blur"
            />
            <CommonIcon
              size="small"
              decorative
              :name="isChecked(item, access) ? 'radio-yes' : 'radio-no'"
              class="shrink-0 rounded-full peer-focus-visible:outline peer-focus-visible:-outline-offset-1 peer-focus-visible:outline-blue-800"
              :class="
                isLocked(item, access)
                  ? 'opacity-40'
                  : 'group-hover:outline group-hover:-outline-offset-1 group-hover:outline-blue-600 dark:group-hover:outline-blue-900'
              "
            />
            <span class="sr-only">{{ cellLabel(item, header) }}</span>
          </label>
        </template>
      </CommonSimpleTable>
    </CommonLoader>
  </output>
</template>
