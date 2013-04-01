class Maple.Routers.ApplicationRouter extends Backbone.Router

  initialize: (options) ->
    @posts = new Maple.Collections.PostsCollection()
    @posts.reset options.posts

    @companies = new Maple.Collections.CompaniesCollection()
    @companies.reset options.companies

  routes:
    '' : 'index'
    'newPost' : 'newPost'
    'companies/:id' : 'showCompany'
    '*default' : 'index'

  index: ->
    @view = new Maple.Views.PostsIndexView({ collection: @posts})
    @view = new Maple.Views.CompaniesIndexView({ collection: @companies})

  newPost: ->
    @view = new Maple.Views.NewPostView({ collection: @posts, companies: [] })

  showCompany: (id) ->
    company = new Maple.Models.Company({ id: id })
    company.fetch success: (data) ->
      $("#maple-main-container").html( new Maple.Views.CompanyShowView({ model: company }).el )