<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { ObjectManagerFrontendAttribute } from '@shared/graphql/types'
import type { ObjectLike } from '@shared/types/utils'
import { objectAttributesConfig } from './config'
import { useDisplayObjectAttributes } from './useDisplayObjectAttributes'

export interface Props {
  object: ObjectLike
  attributes: ObjectManagerFrontendAttribute[]
  skipAttributes?: string[]
  accessors?: Record<string, string>
}

const props = defineProps<Props>()

const { fields } = useDisplayObjectAttributes(props)
</script>

<template>
  <Component :is="objectAttributesConfig.outer" v-if="fields.length">
    <template v-for="field of fields" :key="field.attribute.name">
      <Component
        :is="objectAttributesConfig.wrapper"
        :label="field.attribute.display"
      >
        <CommonLink
          v-if="field.link"
          :link="field.link"
          :class="objectAttributesConfig.classes.link"
        >
          <Component
            :is="field.component"
            :attribute="field.attribute"
            :value="field.value"
          />
        </CommonLink>
        <Component
          :is="field.component"
          v-else
          :attribute="field.attribute"
          :value="field.value"
        />
      </Component>
    </template>
    <slot name="after-fields" />
  </Component>
</template>
