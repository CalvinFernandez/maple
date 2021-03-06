include ActionView::Helpers::DateHelper

class Post < ActiveRecord::Base
  include Tire::Model::Search
  include Tire::Model::Callbacks

  # A post has the following fields:
  # id, title, content, created_at,
  # updated_at, user_id, image_file_name,
  # image_content_type, image_file_size,
  # image_updated_at, company_id.

  attr_accessible :content, :title, :image, :company_id

  has_attached_file :image, :styles => { :medium => "250x250>", :thumb => "100x100>" }, :default_url => "posts/:style/missing.png"

  belongs_to :user
  belongs_to :company
  belongs_to :campaign

  acts_as_voteable

  has_many :comments, :as => :commentable
  validates_associated :comments
  
  has_and_belongs_to_many :rewards

  mapping do
    indexes :_id, index: :not_analyzed
    indexes :title
    indexes :content
    indexes :company_id, type: "integer"
    indexes :user_id, type: "integer"
    indexes :total_votes, type: "integer", index: :not_analyzed
    indexes :created_at, type: "date", index: :not_analyzed
  end

  module VOTED
    NO = 'no'
    YES = 'yes'
    UNAVAILABLE = 'unavailable'
  end

  def to_indexed_json
    self.public_model
  end

  def public_model(options = {})
    # public_model(options):
    # Parameters: "options" - "user" key should be
    # the logged in user
    # Returned JSON includes the author, company,
    # full_image_url, image_url, total_votes,
    # and voted_on

    post_json = self.as_json(:include => [:user, :company])

    post_json[:full_image_url] = self.image.url
    post_json[:image_url] = self.image.url(:medium)
    post_json[:total_votes] = self.votes_for
    post_json[:voted_on] = self.voted_on(options[:user])
    post_json[:relative_time] = time_ago_in_words(self.created_at)

    post_json.to_json
  end

  def self.public_models(posts, options = {})
    # self.public_models(posts, options):
    # Parameters: "posts" - Array of posts
    # to convert into JSON, "options" - "user" key
    # should be the logged in user
    # Returned JSON includes the author, company,
    # full_image_url, image_url, total_votes
    # and voted_on

    Jbuilder.encode do |json|
      json.array! posts do |json, post|
        json.(post, :id, :company, :company_id, :content, :created_at, :title, :user)
        json.full_image_url post.image.url
        json.image_url post.image.url(:medium)
        json.total_votes post.votes_for
        json.voted_on post.voted_on(options[:user])
        json.timestamp post.created_at.to_i
        json.user_id post.user.id if post.user
        json.relative_time time_ago_in_words(post.created_at)
      end
    end
  end

  def self.paged_posts(options = {})
    # self.paged_posts(options):
    # Parameters: "options" - "company" key
    # is the post's associated Company, "page"
    # key sets the page of Posts to retrieve (defaults
    # to 1)
    # Retrieves all of the Posts and includes
    # the associated Company for a Post if
    # it exists.
    # Sorts the results by the number of votes.
    options[:page] ||= 1
    options[:crumb] ||= 'title'
    options[:query] ||= '*'

    s = self.search(load: true, page: options[:page], per_page: 30) do
      query do
        string "#{options[:crumb]}:#{options[:query]}", default_operator: 'AND'
      end

      filter :term, { :company_id => options[:company_id] } if options[:company_id].present?
      filter :term, { :user_id => options[:user_id] } if options[:user_id].present?

      if options[:sort].present?
        sort do
          by options[:sort][:by], (options[:sort][:order] || "desc")
        end
      end
    end
  end

  def voted_on(user = nil)
    return self.voted_by?(user) ? VOTED::YES : VOTED::NO if user

    VOTED::UNAVAILABLE
  end

  def update_rewards 
    if self.campaign   
      self.campaign.rewards.each do |reward|
        unless self.rewards.include?(reward)
          if reward.qualifies_for?(self)
            # Post qualifies for an award that it doesn't already have.
            # Add it to the collection of awards owned by the post
            # Add it to the collection of awards owned by the user
           
            self.rewards << reward        
            
            self.user.rewards << reward 
            reward.one_less
          end
        end
      end
    end
  end
end
