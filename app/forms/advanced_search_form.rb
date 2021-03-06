# frozen_string_literal: true

# NOTE: This code is a subspecies of Extract Form Objects at https://codeclimate.com/blog/7-ways-to-decompose-fat-activerecord-models/
class AdvancedSearchForm
  include Virtus.model
  include ActiveModel::Model

  def self.model_name
    # FIXME: Maybe the class name at line 3 should be PostsSearchForm instead of AdvancedSearchForm.
    ActiveModel::Name.new(self, nil, 'PostsSearchForm')
  end

  FORM_FIELDS = %i[
    from
    since
    till
  ].freeze

  FORM_FIELDS.each do |f|
    attribute f, String
  end

  # NOTE: You can define attributes as follows, too.
  #   This might look simpler, but bear in mind that you have to define FORM_FIELDS, too.
  #   Because the attributes are refered in app/controllers/posts_controller.rb
  # attribute :from, String
  # attribute :since, String
  # attribute :till, String
  # FORM_FIELDS = %i[from since till]

  def initialize(params)
    @posts_search_form = params[:posts_search_form] || {}
    FORM_FIELDS.each { |f| send("#{f}=", @posts_search_form[f]) }
  end

  # TODO: Full text search should be considered for keyword search.
  # rubocop:disable Metrics/AbcSize
  def search
    return Post.none if @posts_search_form.empty?

    query = Post.includes(:user).order('posts.created_at desc')
    query = query.joins(:user).where(users: { screen_name: from }) if from.present?
    query = query.where('posts.created_at >= ?', Time.zone.parse(since)) if since.present?
    query = query.where('posts.created_at < ?', Time.zone.parse(till) + 1.day) if till.present?
    query
  end
  # rubocop:enable Metrics/AbcSize

  # NOTE: The following are examples of the search method with yield_self.
  #
  # Version (1)
  #
  # def search
  #   return Post.none if @posts_search_form.empty?
  #
  #   Post
  #     .includes(:user)
  #     .order('posts.created_at desc')
  #     .yield_self(&method(:filter_by_screen_name))
  #     .yield_self(&method(:filter_by_since))
  #     .yield_self(&method(:filter_by_till))
  # end
  #
  # private
  #
  # def filter_by_screen_name(posts)
  #   return posts.joins(:user).where(users: { screen_name: from }) if from.present?
  #   posts
  # end
  #
  # def filter_by_since(posts)
  #   return posts.where('posts.created_at >= ?', Time.zone.parse(since)) if since.present?
  #   posts
  # end
  #
  # def filter_by_till(posts)
  #   return posts.where('posts.created_at < ?', Time.zone.parse(till) + 1.day) if till.present?
  #   posts
  # end

  # Version (2)
  #
  # def search
  #   return Post.none if @posts_search_form.empty?
  #
  #   Post.includes(:user).order('posts.created_at desc').yield_self { |posts|
  #     from.present? ? posts.joins(:user).where(users: { screen_name: from }) : posts
  #   }.yield_self { |posts|
  #     since.present? ? posts.where('posts.created_at >= ?', Time.zone.parse(since)) : posts
  #   }.yield_self { |posts|
  #     till.present? ? posts.where('posts.created_at < ?', Time.zone.parse(till) + 1.day) : posts
  #   }
  # end
end
