<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { nextTick, ref, shallowRef, watchEffect } from 'vue'
import { useActiveElement, useMagicKeys, onClickOutside } from '@vueuse/core'
import { i18n } from '#shared/i18n.ts'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonIcon from '#shared/components/CommonIcon/CommonIcon.vue'

const filterFieldOpen = ref(false)
const containerNode = ref<HTMLDivElement>()
const searchText = defineModel<string>({ required: true, default: '' })
const searchTextField = shallowRef<HTMLInputElement>()

onClickOutside(containerNode, () => {
  if (searchText.value !== '') return

  filterFieldOpen.value = false
})

const activeElement = useActiveElement()
const { escape } = useMagicKeys()

const openFilterField = () => {
  filterFieldOpen.value = true

  nextTick(() => searchTextField.value?.focus())
}

const closeFilterField = () => {
  filterFieldOpen.value = false
  searchText.value = ''
}

watchEffect(() => {
  if (!escape.value) return
  if (activeElement.value !== searchTextField.value) return

  closeFilterField()
})
</script>

<template>
  <div
    ref="containerNode"
    class="flex items-center gap-2 transition-colors h-10 rounded-lg mb-2"
    :class="{
      'px-2 bg-blue-200 dark:bg-gray-700 has-[input:hover]:outline has-[input:hover]:outline-1 has-[input:hover]:outline-offset-1 has-[input:hover]:outline-blue-600 dark:has-[input:hover]:outline-blue-900 has-[input:focus]:outline has-[input:focus]:outline-1 has-[input:focus]:outline-offset-1 has-[input:focus]:outline-blue-800 has-[input:hover]:has-[input:focus]:outline-blue-800 dark:has-[input:hover]:has-[input:focus]:outline-blue-800':
        filterFieldOpen,
    }"
  >
    <CommonIcon
      v-if="filterFieldOpen"
      class="fill-stone-200 dark:fill-neutral-500"
      size="small"
      name="filter"
      decorative
    />
    <CommonButton
      v-else
      class="rtl:mr-auto ltr:ml-auto"
      prefix-icon="filter"
      @click="openFilterField"
    >
      {{ $t('filter') }}
    </CommonButton>

    <input
      ref="searchTextField"
      v-model.trim="searchText"
      :placeholder="$t('Filter settings…')"
      class="w-0 duration-200 transition-[width] focus:outline-none bg-transparent text-sm text-black dark:text-white"
      :class="{ 'w-full': filterFieldOpen }"
      type="text"
      role="searchbox"
    />
    <Transition name="fade-out-delay">
      <CommonButton
        v-if="filterFieldOpen"
        icon="x-lg"
        variant="neutral"
        class="hover:outline-none hover:outline-transparent hover:text-black hover:dark:text-white"
        :aria-label="i18n.t('Clear filter')"
        @click="closeFilterField"
      />
    </Transition>
  </div>
</template>

<style scoped>
.fade-out-delay {
  &-enter-active,
  &-leave-active {
    transition: opacity 0.3s ease;
  }

  &-enter-active {
    transition-delay: 50ms;
  }

  &-enter-from {
    opacity: 0;
  }

  &-enter-to {
    opacity: 1;
  }

  &-leave-from {
    opacity: 1;
  }

  &-leave-to {
    opacity: 0;
  }
}
</style>
