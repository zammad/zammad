// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

const getRoot = () => document.querySelector(':root') as HTMLElement

export const usePrintMode = () => {
  const isPrintMode = ref(false)

  const turnOnPrintMode = () => {
    getRoot().dataset.printMode = 'true'
    isPrintMode.value = true
  }

  const turnOffPrintMode = () => {
    delete getRoot().dataset.printMode
    isPrintMode.value = false
  }

  const printPage = () => {
    turnOnPrintMode()

    window?.print()

    turnOffPrintMode()
  }

  return {
    isPrintMode,
    turnOnPrintMode,
    turnOffPrintMode,
    printPage,
  }
}
