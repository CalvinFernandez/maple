class Maple.Views.PostShowView extends Backbone.View

  template: JST['backbone/templates/posts/show']

  initialize: ->
    @session = @options.session || ""   
    @render()

  render: ->
    @$el.html(@template(_.extend(@model.toJSON())))
  
