class PostsController < ApplicationController

  before_filter :check_for_token

  def create
    # post posts/:id
    #
    # This route will create a new ad with the given id. It will
    # also log in mobile users that are posting an ad.

    post = Post.new(sanitize(params[:post]))

    success = false

    if user_signed_in?

      current_user.posts << post
      post.user = current_user

      current_user.save
      success = post.save

    end

    options = {}
    options[:user] = current_user if current_user
    if success
      render :json => post.public_model(options)
    else
      render :json => post.public_model(options),
             :status => Rack::Utils.status_code(400)
    end
  end

  def index
    # get posts
    #
    # This route will return all the posts and filter if there are
    # options specified. Currently we can filter by company
    posts = Post.paged_posts(params)

    render :json => Post.public_models(posts, {:user => current_user})
  end

  def new
    # get posts/new
    #
    # This route will a new post with the specified parameters without
    # saving it to the database
    post = Post.new(params[:post])

    render :json => post.public_model
  end

  def vote_up
    # post posts/vote_up
    #
    # This will increment the vote for the selected post by 1

    post = Post.find_by_id(params[:post_id])

    current_user.vote_for(post)
    post.update_rewards 

    render :json => post
  end

  def destroy
    post = Post.destroy(params[:id])

    render :json => post.public_model
  end

  def sanitize(model)
    sanitized = {}
    Post.attr_accessible[:default].each do |attr|
      sanitized[attr] = model[attr] if model[attr]
    end
    sanitized
  end

  private

  def check_for_token
    user = FbGraph::User.me(params[:token]) unless params[:token].nil?
    if !user.nil?
      user = user.fetch
      logged_in_user = User.find_by_uid(user.identifier)
      sign_in(:user, logged_in_user)
    end
  end
end
