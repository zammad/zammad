// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

let abstracts = {
  durations: {
    normal: {
      enter: 0,
      leave: 0,
    },
  },
}

export const initializeAbstracts = (abstractsArgs: typeof abstracts) => {
  abstracts = abstractsArgs
}

export const getAbstracts = () => abstracts
