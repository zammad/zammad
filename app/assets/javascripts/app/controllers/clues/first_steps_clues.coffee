class App.FirstStepsClues extends App.CluesBase
  clues: [
    {
      container: '.js-dashboardMenuItem'
      headline: __('Dashboard')
      text: __('Here you see a quick overview of your and other agents\' performance.')
      actions: [
        'hover'
      ]
    }
    {
      container: '.search-holder'
      headline: __('Search')
      text: __('Here you can search for tickets, customers, and organizations. Use the asterisk §*§ to find anything, e.g. §smi*§ or §rosent*l§. You also can use ||quotation marks|| for searching phrases: §"some phrase"§.')
      actions: []
    }
    {
      container: '.user-menu .add'
      headline: __('Create')
      text: __('Here you can create new tickets, customers and organizations (depending on your configured permissions).')
      actions: [
        'hover .navigation',
        'hover .user-menu .add'
      ]
    }
    {
      container: '.user-menu .user .dropdown-menu'
      headline: __('Personal Settings')
      text: __('Here you can sign out, change the frontend language, and see your last viewed items.')
      actions: [
        'hover .navigation',
        'click .user-menu .user .js-action',
        'hover .user-menu .user'
      ]
    }
    {
      container: '.js-overviewsMenuItem'
      headline: __('Overviews')
      text: __('Here you find your ticket overviews for open, assigned, and escalated tickets.')
      actions: [
        'hover'
      ]
    }
  ]
