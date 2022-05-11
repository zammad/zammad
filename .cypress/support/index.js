// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import '@mobile/styles/main.css'
import 'virtual:svg-icons-register' // eslint-disable-line import/no-unresolved

import './commands'

document.body.className = 'bg-black text-white'

// eslint-disable-next-line no-underscore-dangle
window.__ = (str) => str
