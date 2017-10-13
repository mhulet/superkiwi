//= require rails-ujs
//= require turbolinks
//= require jquery
//= require ladda/dist/spin.min
//= require ladda/dist/ladda.min

$(document).on 'turbolinks:load', ->
  Ladda.bind '.ladda-button'
