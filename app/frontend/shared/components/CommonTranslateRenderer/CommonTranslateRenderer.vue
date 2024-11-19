<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { defineProps, computed } from 'vue'

import { i18n } from '#shared/i18n.ts'

import type { PlaceholderRenderType, RenderPlaceholder } from './types.ts'

interface Props {
  source: string
  placeholders: (string | RenderPlaceholder)[]
}

const typeComponents: Record<PlaceholderRenderType, string> = {
  link: 'CommonLink',
  datetime: 'CommonDateTime',
  label: 'CommonLabel',
  badge: 'CommonBadge',
}

const props = defineProps<Props>()

const translatedSourcePieces = computed(() => {
  const translatedSource = i18n.t(
    props.source,
    ...props.placeholders.map((placeholder) => {
      return typeof placeholder === 'string' ? placeholder : `%s`
    }),
  )

  const filteredPlaceholders = props.placeholders.filter(
    (ph) => typeof ph === 'object',
  )

  const translatedSourcePieces: (string | RenderPlaceholder)[] = []
  const translatedSourceParts = translatedSource.split('%s')
  translatedSourceParts.forEach((part, index) => {
    // Add the text part to the result
    if (part) translatedSourcePieces.push(part)

    // Add the corresponding placeholder if available
    if (index < translatedSourceParts.length - 1) {
      const placeholder = filteredPlaceholders[index]
      translatedSourcePieces.push(placeholder)
    }
  })

  return translatedSourcePieces
})
</script>

<template>
  <span>
    <template v-for="(translatedSourcePiece, index) in translatedSourcePieces">
      <template v-if="typeof translatedSourcePiece === 'string'">
        {{ translatedSourcePiece }}
      </template>
      <template v-else>
        <component
          :is="typeComponents[translatedSourcePiece.type]"
          :key="`${translatedSourcePiece.type}-${index}`"
          v-bind="translatedSourcePiece.props"
        >
          <template v-if="translatedSourcePiece.content" #default>
            {{ translatedSourcePiece.content }}
          </template>
        </component>
      </template>
    </template>
  </span>
</template>
