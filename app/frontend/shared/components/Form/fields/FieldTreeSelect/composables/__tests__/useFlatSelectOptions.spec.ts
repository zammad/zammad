// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { effectScope, nextTick, ref } from 'vue'

import type { TreeSelectOption } from '#shared/components/Form/fields/FieldTreeSelect/types.ts'

import useFlatSelectOptions from '../useFlatSelectOptions.ts'

describe('useFlatSelectOptions', () => {
  it('removes appended options that become available in base options', async () => {
    const scope = effectScope()

    await scope.run(async () => {
      const baseOptions = ref<TreeSelectOption[]>([{ value: 'a', label: 'A' }])

      const { appendedTreeOptions } = useFlatSelectOptions(baseOptions)

      appendedTreeOptions.value = [
        { value: 'b', label: 'B' },
        { value: 'c', label: 'C' },
      ]

      // Simulate formUpdater providing only option 'b'.
      baseOptions.value = [
        { value: 'a', label: 'A' },
        { value: 'b', label: 'B' },
      ]
      await nextTick()

      expect(appendedTreeOptions.value).toEqual([{ value: 'c', label: 'C' }])
    })

    scope.stop()
  })

  it('preserves parent structure when only the child is new', async () => {
    const scope = effectScope()

    await scope.run(async () => {
      const baseOptions = ref<TreeSelectOption[]>([
        {
          value: 'Support',
          label: 'Support',
          children: [{ value: 'Support::L1', label: 'L1' }],
        },
      ])

      const { appendedTreeOptions } = useFlatSelectOptions(baseOptions)

      // appendToTree would build this structure for "Support::L2::Incident".
      appendedTreeOptions.value = [
        {
          value: 'Support',
          label: 'Support',
          children: [
            {
              value: 'Support::L2',
              label: 'L2',
              children: [{ value: 'Support::L2::Incident', label: 'Incident' }],
            },
          ],
        },
      ]

      // Trigger the watcher (base options unchanged but reassigned).
      baseOptions.value = [...baseOptions.value]
      await nextTick()

      // Parent nodes kept because the nested child is still new.
      expect(appendedTreeOptions.value).toEqual([
        {
          value: 'Support',
          label: 'Support',
          children: [
            {
              value: 'Support::L2',
              label: 'L2',
              children: [{ value: 'Support::L2::Incident', label: 'Incident' }],
            },
          ],
        },
      ])
    })

    scope.stop()
  })
})
