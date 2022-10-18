<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, onMounted, ref, toRef } from 'vue'
import type { CommonInputSearchExpose } from '@shared/components/CommonInputSearch/CommonInputSearch.vue'
import CommonInputSearch from '@shared/components/CommonInputSearch/CommonInputSearch.vue'
import CommonDialog from '@mobile/components/CommonDialog/CommonDialog.vue'
import { i18n } from '@shared/i18n'
import type { FieldTagsContext } from './types'
import useValue from '../../composables/useValue'

interface Props {
  name: string
  context: FieldTagsContext
}

// TODO call API to get/create tags

const props = defineProps<Props>()
const { localValue } = useValue(toRef(props, 'context'))
const currentValue = computed(() => localValue.value || [])
const isCurrentValue = (tag: string) => currentValue.value.includes(tag)

const filter = ref('')
const newTags = ref<{ value: string; label: string }[]>([])

const translatedOptions = computed(() => {
  const {
    options = [],
    noOptionsLabelTranslation,
    sorting = 'label',
  } = props.context

  const allOptions = [...options, ...newTags.value].sort((a, b) => {
    const a1 = (a[sorting] || '').toString()
    const b1 = (b[sorting] || '').toString()
    return a1.localeCompare(b1)
  })

  if (!options || !noOptionsLabelTranslation) return allOptions

  return allOptions.map((option) => {
    option.label = i18n.t(option.label, ...(option.labelPlaceholder || []))
    return option
  })
})

const tagExists = (tag: string) => {
  return translatedOptions.value.some((option) => option.value === tag)
}

const filteredTags = computed(() => {
  if (!filter.value) return translatedOptions.value

  return translatedOptions.value.filter((tag) =>
    tag.label.toLowerCase().includes(filter.value.toLowerCase()),
  )
})

const removeTag = (tag: string) => {
  const newValue = currentValue.value.filter((item: string) => item !== tag)
  props.context.node.input(newValue)
}

const toggleTag = (tag: string) => {
  const normalizedValue = [...currentValue.value]
  if (normalizedValue.includes(tag)) {
    removeTag(tag)
    return
  }
  normalizedValue.push(tag)
  props.context.node.input(normalizedValue)
}

const createTag = () => {
  const tag = filter.value
  if (tagExists(tag)) return

  toggleTag(tag)
  newTags.value.push({
    value: tag,
    label: tag,
  })
}

const filterInput = ref<CommonInputSearchExpose>()

onMounted(() => {
  filterInput.value?.focus()
})
</script>

<template>
  <CommonDialog :label="__('Tags')" :name="name">
    <div class="w-full border-b border-white/10 p-4">
      <CommonInputSearch
        ref="filterInput"
        v-model="filter"
        placeholder="Tag name…"
        @keydown.enter="createTag()"
      >
        <template v-if="context.canCreate" #controls>
          <button
            v-if="filter.length > 0"
            :title="$t('Create tag')"
            class="rounded-3xl bg-green text-white"
            :class="{
              'bg-green/40 text-white/20': tagExists(filter),
            }"
            :disabled="tagExists(filter)"
            @click="createTag()"
          >
            <CommonIcon class="p-1" size="tiny" name="mobile-add" decorative />
          </button>
        </template>
      </CommonInputSearch>
    </div>
    <div class="flex w-full flex-col px-4">
      <button
        v-for="option of filteredTags"
        :key="option.value"
        class="flex w-full items-center"
        @click="toggleTag(option.value)"
      >
        <CommonIcon
          :class="{
            '!text-white': isCurrentValue(option.value),
          }"
          :name="
            isCurrentValue(option.value)
              ? 'mobile-check-box-yes'
              : 'mobile-check-box-no'
          "
          class="mr-3 text-white/50"
          size="base"
          decorative
        />

        <span class="flex-1 py-3 text-left">
          {{ option.label }}
        </span>
      </button>
    </div>
  </CommonDialog>
</template>
