class CompaniesController < ApplicationController

  def index
    # get companies
    #
    # This will get all the companies (30 at a time)
    options = {}

    followed = User.find(params[:follower]).
      follows_by_type('Company').
      map(&:followable_id) if params[:follower].present?

    options = { :followed => followed } if !followed.nil?
    options = { :followed => [-1] } if !followed.nil? && followed.empty?

    companies = Company.paged_companies(options)

  	render :json => Company.public_models(companies)
  end

  def show
  	# show company
  	#
  	# This will show a specific company
  	if current_company && current_company.id == params[:id].to_i
  		render :json => current_company.public_model({:user => current_user, :company => current_company})
  	else
  		render :json => Company.find(params[:id]).public_model({:user => current_user, :company => current_company})
    end
  end

  def update
    @company = Company.find(params[:id])
    if current_company && current_company.id == @company.id
      @company.update_attributes(sanitize(params[:company]))
      render :json => @company.public_model({:user => current_user, :company => current_company})
      #render :json => {}, :status => 200
    else
      render :json => {}, :status => 403
    end
  end

  def destroy
    company = Company.delete(params[:id])

    render :json => company.public_model
  end

  def sanitize(model)
    sanitized = {}
    Company.attr_accessible[:default].each do |attr|
      sanitized[attr] = model[attr] if model[attr]
    end
    sanitized
  end

  def dashboard
    company = Company.find(params[:id])
    num_ads = company.posts.length
    num_followers = company.followers.length
    dashboard = { :num_ads => num_ads, :num_followers => num_followers }
    contributors = []

    company.posts.each do |post|
      user = post.user
      found = contributors.select { |c| c[:id] == user.id }

      if found.empty?
        contributors.push({:id => user.id, :name => user.name, :uid => user.uid, :num_ads => 1, :num_votes => post.votes.size})
      else
        found.first[:num_ads] += 1
        found.first[:num_votes] += post.votes.size
      end

    end

    contributors.sort_by { |c| c[:num_ads] }
    dashboard[:contributors] = contributors

    render :json => dashboard

  end
end
