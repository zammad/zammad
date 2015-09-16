class App.UiElement.business_hours
  @render: (attribute, params) ->

    hours = {
      mon: {
        active: true
        timeframes: ['09:00-17:00']
      }
      tue: {
        active: true
        timeframes: ['00:00-24:00']
      }
      wed: {
        active: true
        timeframes: ['09:00-17:00']
      }
      thu: {
        active: true
        timeframes: ['09:00-12:00', '13:00-17:00']
      }
      fri: {
        active: true
        timeframes: ['09:00-17:00']
      }
      sat: {
        active: false
        timeframes: ['10:00-14:00']
      }
      sun: {
        active: false
        timeframes: ['10:00-14:00']
      }
    }

    businessHours = new App.BusinessHours
      hours: hours

    businessHours.render()
    businessHours.el