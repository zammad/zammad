<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import { cloneDeep, isEqual } from 'lodash-es'
import { computed, reactive, toRef, watch } from 'vue'

import type { SelectValue } from '#shared/components/CommonSelect/types.ts'
import useValue from '#shared/components/Form/composables/useValue.ts'
import type { TreeSelectOption } from '#shared/components/Form/fields/FieldTreeSelect/types.ts'
import { useDelegateFocus } from '#shared/composables/useDelegateFocus.ts'
import getUuid from '#shared/utils/getUuid.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

import useFlatSelectOptions from '../FieldTreeSelect/useFlatSelectOptions.ts'

import {
  GroupAccess,
  type GroupPermissionReactive,
  type GroupPermissionsContext,
} from './types.ts'

interface Props {
  context: GroupPermissionsContext
}

const props = defineProps<Props>()

const contextReactive = toRef(props, 'context')

const { localValue } = useValue(contextReactive)

const { flatOptions } = useFlatSelectOptions(toRef(props.context, 'options'))

const groupPermissions = reactive<GroupPermissionReactive[]>([])
const groupOptions = reactive<TreeSelectOption[][]>([])

const groupAccesses = [
  {
    access: GroupAccess.Read,
    label: __('Read'),
  },
  {
    access: GroupAccess.Create,
    label: __('Create'),
  },
  {
    access: GroupAccess.Change,
    label: __('Change'),
  },
  {
    access: GroupAccess.Overview,
    label: __('Overview'),
  },
  {
    access: GroupAccess.Full,
    label: __('Full'),
  },
]

const getTakenGroups = (index: number): SelectValue[] =>
  groupPermissions.reduce((takenGroups, groupPermission, currentIndex) => {
    if (currentIndex !== index && groupPermission.groups)
      takenGroups.push(...(groupPermission.groups as unknown as SelectValue[]))
    return takenGroups
  }, [] as SelectValue[])

const filterTreeSelectOptions = (options: TreeSelectOption[], index: number) =>
  options.filter((group) => {
    if (group.children) {
      const children = filterTreeSelectOptions(group.children, index)

      if (children.length) {
        group.children = children

        // Set the parent option to disabled in case it's taken, but there are child options available.
        group.disabled = getTakenGroups(index).includes(group.value)

        return true
      }
    }

    // Remove empty children options.
    delete group.children

    return !getTakenGroups(index).includes(group.value)
  })

const filterGroupOptions = (index: number) =>
  filterTreeSelectOptions(cloneDeep(contextReactive.value.options || []), index)

const getNewGroupPermission = () => ({
  key: getUuid(),
  groups: [] as unknown as SelectValue,
  groupAccess: groupAccesses.reduce(
    (groupAccess, { access }) => {
      groupAccess[access] = false

      return groupAccess
    },
    {} as Record<GroupAccess, boolean>,
  ),
})

const addGroupPermission = (index: number) => {
  groupOptions[index] = filterGroupOptions(index)
  groupPermissions.splice(index, 0, getNewGroupPermission())
}

const removeGroupPermission = (index: number) => {
  groupPermissions.splice(index, 1)
  groupOptions.splice(index, 1)
}

watch(
  groupPermissions,
  (newValue) => {
    // Set external value to internal one, but only if they differ (loop protection).
    if (isEqual(newValue, localValue.value)) return

    newValue.forEach((_groupPermission, index) => {
      groupOptions[index] = filterGroupOptions(index)
    })

    localValue.value = cloneDeep(newValue)
  },
  {
    deep: true,
  },
)

watch(
  localValue,
  (newValue) => {
    if (!newValue || !newValue.length) {
      groupOptions.splice(0, groupOptions.length, filterGroupOptions(0))

      groupPermissions.splice(
        0,
        groupPermissions.length,
        getNewGroupPermission(),
      )

      return
    }

    // Set internal value to external one, but only if they differ (loop protection).
    if (isEqual(newValue, groupPermissions)) return

    const newValues = cloneDeep(newValue || []) as GroupPermissionReactive[]
    newValues.forEach((groupPermission, index) => {
      groupPermission.key = getUuid()
      groupOptions[index] = filterGroupOptions(index)
    })

    groupPermissions.splice(0, groupPermissions.length, ...newValues)
  },
  {
    immediate: true,
  },
)

const hasLastGroupPermission = computed(() => groupPermissions.length === 1)

const hasNoMoreGroups = computed(
  () =>
    !flatOptions.value.length ||
    groupPermissions.reduce((emptyGroups, groupPermission) => {
      if (!((groupPermission.groups as unknown as SelectValue[]) || []).length)
        emptyGroups += 1
      return emptyGroups
    }, 0) > 0 ||
    groupPermissions.reduce(
      (selectedGroupCount, groupPermission) =>
        selectedGroupCount +
        ((groupPermission.groups as unknown as SelectValue[]) || []).length,
      0,
    ) === flatOptions.value.length,
)

const { delegateFocus } = useDelegateFocus(
  contextReactive.value.id,
  `${contextReactive.value.id}_first_element`,
)

const ensureGranularOrFullAccess = (
  groupAccess: Record<GroupAccess, boolean>,
  access: GroupAccess,
  value: boolean,
) => {
  if (value === false) return

  if (access === GroupAccess.Full && value === true) {
    Object.entries(groupAccess).forEach(([key, state]) => {
      if (key !== GroupAccess.Full && state === true) {
        groupAccess[key as GroupAccess] = false
      }
    })
  } else if (
    access !== GroupAccess.Full &&
    groupAccess[GroupAccess.Full] === true
  )
    groupAccess[GroupAccess.Full] = false
}
</script>

<template>
  <output
    :id="context.id"
    class="flex w-full flex-col space-y-2 rounded-lg p-2 focus:outline focus:outline-1 focus:outline-offset-1 focus:outline-blue-800 hover:focus:outline-blue-800"
    :class="context.classes.input"
    :name="context.node.name"
    role="list"
    :tabindex="context.disabled ? '-1' : '0'"
    :aria-disabled="context.disabled"
    :aria-describedby="context.describedBy"
    v-bind="context.attrs"
    @focus="delegateFocus"
  >
    <div
      v-for="(groupPermission, index) in groupPermissions"
      :key="groupPermission.key"
      class="flex w-full items-center gap-3"
      role="listitem"
    >
      <FormKit
        :id="index === 0 ? `${context.id}_first_element` : undefined"
        v-model="groupPermission.groups"
        type="treeselect"
        outer-class="grow"
        :ignore="true"
        :options="groupOptions[index]"
        :clearable="true"
        :multiple="true"
        :disabled="context.disabled"
        :alternative-background="true"
        :no-options-label-translation="true"
        @blur="index === 0 ? context.handlers.blur : undefined"
      />
      <FormKit
        v-for="groupAccess in groupAccesses"
        :key="groupAccess.access"
        v-model="groupPermission.groupAccess[groupAccess.access]"
        type="checkbox"
        wrapper-class="shrink-0 flex-col-reverse"
        :ignore="true"
        :disabled="context.disabled"
        :alternative-border="true"
        @input="
          ensureGranularOrFullAccess(
            groupPermission.groupAccess,
            groupAccess.access,
            $event!,
          )
        "
      >
        <template #label>
          <CommonLabel
            class="uppercase text-gray-300 dark:text-neutral-400"
            size="small"
          >
            {{ $t(groupAccess.label) }}
          </CommonLabel>
        </template>
      </FormKit>
      <CommonButton
        class="shrink-0 text-gray-300 dark:text-neutral-400"
        icon="dash-circle"
        size="medium"
        :aria-label="$t('Remove')"
        :disabled="hasLastGroupPermission"
        :tabindex="hasLastGroupPermission ? '-1' : '0'"
        @click="removeGroupPermission(index)"
      />
      <CommonButton
        class="me-2.5 shrink-0 text-gray-300 dark:text-neutral-400"
        icon="plus-circle"
        size="medium"
        :aria-label="$t('Add')"
        :disabled="hasNoMoreGroups"
        :tabindex="hasNoMoreGroups ? '-1' : '0'"
        @click="addGroupPermission(index + 1)"
      />
    </div>
  </output>
</template>
