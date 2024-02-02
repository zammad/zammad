<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import { computed, onMounted, reactive, toRef, watch } from 'vue'
import { cloneDeep } from 'lodash-es'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import type { SelectValue } from '#shared/components/CommonSelect/types.ts'
import type { TreeSelectOption } from '#shared/components/Form/fields/FieldTreeSelect/types.ts'
import useValue from '#shared/components/Form/composables/useValue.ts'
import useFlatSelectOptions from '../FieldTreeSelect/useFlatSelectOptions.ts'
import type {
  GroupAccessLookup,
  GroupPermissionReactive,
  GroupPermissionsContext,
} from './types.ts'

interface Props {
  context: GroupPermissionsContext
}

const props = defineProps<Props>()

const contextReactive = toRef(props, 'context')

const { localValue } = useValue(contextReactive)

const { flatOptions } = useFlatSelectOptions(toRef(props.context, 'groups'))

const groupPermissions = computed<GroupPermissionReactive[]>({
  get() {
    return localValue.value || []
  },

  set(value) {
    localValue.value = value
  },
})

const groupOptions = reactive<TreeSelectOption[][]>([])

const getTakenGroups = (index: number): SelectValue[] =>
  groupPermissions.value.reduce(
    (takenGroups, groupPermission, currentIndex) => {
      if (currentIndex !== index && groupPermission.groups)
        takenGroups.push(
          ...(groupPermission.groups as unknown as SelectValue[]),
        )
      return takenGroups
    },
    [] as SelectValue[],
  )

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
  filterTreeSelectOptions(cloneDeep(contextReactive.value.groups), index)

const getNewGroupPermission = () =>
  reactive<GroupPermissionReactive>({
    groups: [] as unknown as SelectValue,
    groupAccess: contextReactive.value.groupAccesses.reduce(
      (groupAccess, { access }) => {
        groupAccess[access] = false

        return groupAccess
      },
      {} as GroupAccessLookup,
    ),
  })

const addGroupPermission = (index: number) => {
  groupOptions[index] = filterGroupOptions(index)
  groupPermissions.value.splice(index, 0, getNewGroupPermission())
}

const removeGroupPermission = (index: number) => {
  groupPermissions.value.splice(index, 1)
  groupOptions.splice(index, 1)
}

watch(
  () => groupPermissions.value,
  () => {
    groupPermissions.value.forEach((_groupPermission, index) => {
      groupOptions[index] = filterGroupOptions(index)
    })
  },
  {
    immediate: true,
    deep: true,
  },
)

onMounted(() => {
  if (groupPermissions.value.length) return

  contextReactive.value.node.input([getNewGroupPermission()])
})

const hasLastGroupPermission = computed(
  () => groupPermissions.value.length === 1,
)

const hasNoMoreGroups = computed(
  () =>
    !flatOptions.value.length ||
    groupPermissions.value.reduce((emptyGroups, groupPermission) => {
      if (!((groupPermission.groups as unknown as SelectValue[]) || []).length)
        emptyGroups += 1
      return emptyGroups
    }, 0) > 0 ||
    groupPermissions.value.reduce(
      (selectedGroupCount, groupPermission) =>
        selectedGroupCount +
        ((groupPermission.groups as unknown as SelectValue[]) || []).length,
      0,
    ) === flatOptions.value.length,
)

const delegateFocus = () => {
  requestAnimationFrame(() => {
    const firstGroupSelection: HTMLOutputElement | null =
      document.querySelector(`#${contextReactive.value.id}_first_element`)

    if (firstGroupSelection) firstGroupSelection.focus()
  })
}
</script>

<template>
  <output
    :id="context.id"
    class="w-full flex flex-col p-2 space-y-2"
    :class="context.classes.input"
    :name="context.node.name"
    role="list"
    :tabindex="context.disabled ? '-1' : '0'"
    :aria-disabled="context.disabled"
    v-bind="context.attrs"
    @focus="delegateFocus"
    @blur="context.handlers.blur"
  >
    <div
      v-for="(groupPermission, index) in groupPermissions"
      :key="
        ((groupPermission.groups as unknown as SelectValue[]) || []).length
          ? `group-permission-groupId-${(groupPermission.groups as unknown as SelectValue[]).join('-')}`
          : `group-permission-index-${index}`
      "
      class="w-full flex items-center gap-5"
      role="listitem"
    >
      <FormKit
        :id="index === 0 ? `${context.id}_first_element` : undefined"
        v-model="groupPermission.groups"
        type="treeselect"
        outer-class="grow"
        :options="groupOptions[index]"
        :clearable="true"
        :multiple="true"
        :disabled="context.disabled"
        :alternative-background="true"
      />
      <FormKit
        v-for="groupAccess in context.groupAccesses"
        :key="groupAccess.access"
        v-model="groupPermission.groupAccess[groupAccess.access]"
        type="checkbox"
        wrapper-class="w-full flex-col-reverse"
        :disabled="context.disabled"
        :alternative-border="true"
      >
        <template #label>
          <CommonLabel class="uppercase text-gray-300" size="small">
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
