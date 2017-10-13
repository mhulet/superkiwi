window.App ||= {}

App.init = ->
  $(document).foundation()
  $('.ladda').ladda('bind')

$(document).ready ->
  App.init()
