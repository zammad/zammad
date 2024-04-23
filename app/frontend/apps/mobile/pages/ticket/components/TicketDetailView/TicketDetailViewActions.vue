<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
defineProps<{
  formInvalid: boolean
  newRepliesCount: number
  newArticlePresent: boolean
  canReply: boolean
  canSave: boolean
  canScrollDown: boolean
  hidden: boolean
}>()

const emit = defineEmits<{
  reply: []
  save: []
}>()

// Turn off transitions in test mode.
const bannerTransitionDuration = VITE_TEST_MODE ? 0 : { enter: 300, leave: 200 }

// Switch to instant scrolling in test mode as it may interfere with subsequent scroll actions in headless mode.
const behavior = VITE_TEST_MODE ? 'instant' : 'smooth'

const scrollDown = () => {
  window.scrollTo({ top: document.body.scrollHeight, behavior })
}
</script>

<template>
  <Transition
    :duration="bannerTransitionDuration"
    enter-from-class="translate-y-full"
    enter-active-class="translate-y-0"
    enter-to-class="-translate-y-1/3"
    leave-from-class="-translate-y-1/3"
    leave-active-class="translate-y-full"
    leave-to-class="translate-y-full"
  >
    <div
      v-if="!hidden"
      class="pb-safe-1 fixed bottom-0 z-10 bg-gray-600/90 px-2 text-white backdrop-blur-lg transition ltr:left-0 ltr:right-0 rtl:left-0 rtl:right-0"
    >
      <div class="relative flex flex-1 items-center gap-2 p-2">
        <div class="flex-1">
          <Transition
            :duration="bannerTransitionDuration"
            enter-from-class="rtl:translate-x-20 ltr:-translate-x-20"
            enter-to-class="rtl:-translate-x-0 ltr:translate-x-0"
            leave-from-class="rtl:-translate-x-0 ltr:translate-x-0"
            leave-to-class="rtl:translate-x-20 ltr:-translate-x-20"
          >
            <button
              v-if="canScrollDown"
              class="bg-blue relative flex h-8 cursor-pointer items-center rounded-2xl px-2 transition"
              :aria-label="
                newRepliesCount
                  ? $t('Scroll down to see %s new replies', newRepliesCount)
                  : $t('Scroll down')
              "
              @click="scrollDown"
            >
              <CommonIcon name="arrow-down" size="small" decorative />
              <span
                v-if="newRepliesCount"
                aria-hidden="true"
                data-test-id="new-replies-count"
                class="bg-yellow absolute top-0 z-10 h-4 min-w-[1rem] rounded-full px-1 text-center text-xs text-black ltr:ml-4 rtl:mr-4"
              >
                {{ newRepliesCount }}
              </span>
            </button>
          </Transition>
        </div>

        <div class="flex gap-2">
          <FormKit
            v-if="canReply"
            variant="secondary"
            input-class="flex gap-1 flex justify-center items-center font-semibold text-base px-3 py-1 !text-white formkit-variant-secondary:bg-blue rounded select-none"
            type="button"
            @click.prevent="emit('reply')"
          >
            <div>
              <CommonIcon name="chat" size="small" decorative />
            </div>
            <span class="line-clamp-1 break-all">
              {{ newArticlePresent ? $t('Edit reply') : $t('Add reply') }}
            </span>
          </FormKit>
          <FormKit
            v-if="canSave"
            variant="submit"
            input-class="font-semibold text-base px-4 py-1 !text-black formkit-variant-primary:bg-yellow rounded select-none"
            wrapper-class="flex justify-center items-center"
            type="button"
            form="form-ticket-edit"
            @click.prevent="emit('save')"
          >
            {{ $t('Save') }}
          </FormKit>
          <button v-if="formInvalid" @click="emit('save')">
            <span
              role="status"
              :aria-label="$t('Validation failed')"
              class="bg-red absolute bottom-7 h-5 w-5 cursor-pointer rounded-full text-center text-xs leading-5 text-black ltr:right-2 rtl:left-2"
            >
              <CommonIcon
                class="mx-auto h-5"
                name="close"
                size="tiny"
                decorative
              />
            </span>
          </button>
        </div>
      </div>
    </div>
  </Transition>
</template>
