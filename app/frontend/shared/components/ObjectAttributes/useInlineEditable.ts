// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { type ComputedRef } from 'vue'
import { computed, nextTick, onMounted } from 'vue'

import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

import { stripDataId } from './utils.ts'

import type { Props } from './ObjectAttributes.vue'
import type { AttributeField } from './useDisplayObjectAttributes'

export const useInlineEditable = (props: Props, fields: ComputedRef<AttributeField[]>) => {
  const inlineEditObjectAttributes = computed(() =>
    fields.value.filter(
      ({ attribute }) => props.inlineEditable && attribute.name in props.inlineEditable,
    ),
  )

  onMounted(() => {
    nextTick(() => {
      inlineEditObjectAttributes.value.forEach(({ attribute, value }) => {
        if (!attribute?.id) return

        getNode(attribute.id)?.on('change', (event) => {
          const mutationFn = props.inlineEditable?.[attribute.name]

          const updatedValue = stripDataId(event.origin.value as string)
          const initialValue = value as string

          // Currently, we pass initial value without data-id attribute
          // TipTap adds it automatically due to the extension for internal reasons
          // So we need to strip it before comparison
          // ⚠️ Trimming won't work here as the innerHTML contain the indentation

          if (updatedValue === initialValue)
            return event.payload.submitToStopEditing(() => Promise.resolve(true))

          if (!mutationFn) {
            if (import.meta.env.DEV)
              console.warn(
                'No mutation call found for attribute:',
                attribute.name,
                `Object: ${props.object.id}`,
              )
            return
          }

          new MutationHandler(mutationFn({}))
            .send({
              id: props.object.id,
              note: event.origin.value as string,
            })
            .then(() => {
              event.payload.submitToStopEditing(() => Promise.resolve(true))
              // Update the value in memory otherwise the next call if the value stays the same trigger the update mutation again
              value = updatedValue
            })
            .catch(() => event.payload.submitToStopEditing(() => Promise.resolve(false)))
        })
      })
    })
  })
}
