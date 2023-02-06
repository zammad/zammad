// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

export interface SelectionData {
  text: string
  html: string
  selection: Selection | null
}

export const getCurrentSelectionData = (): SelectionData => {
  let text = ''
  let html = ''
  let sel: Selection | null = null
  if (window.getSelection) {
    sel = window.getSelection()
    text = sel?.toString() || ''
  } else if (document.getSelection) {
    sel = document.getSelection()
    text = sel?.toString() || ''
  }

  if (sel && sel.rangeCount) {
    const container = document.createElement('div')
    for (let i = 1; i <= sel.rangeCount; i += 1) {
      container.appendChild(sel.getRangeAt(i - 1).cloneContents())
    }
    html = container.innerHTML
  }

  return {
    text: text.toString().trim() || '',
    html,
    selection: sel,
  }
}
