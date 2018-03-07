# frozen_string_literal: true

class UsersController < ApplicationController
  skip_before_action :require_login, only: %i[new create]
  before_action :set_user, only: %i[follow unfollow]

  def show
    @user = User.find_by(screen_name: params[:screen_name])
    @posts = @user.posts.page(params[:page])
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      auto_login(@user)
      redirect_to root_url, notice: 'Signed up'
    else
      render :new
    end
  end

  def who_to_follow
    @users = User.not_following_users(current_user).page(params[:page])
  end

  # TODO: follow and unfollow should be done by ajax.
  # TODO: fallback_location in follow and unfollow can be changed.
  def follow
    current_user.follow(@user)
    redirect_back(fallback_location: root_url, notice: "Following #{@user.email}")
  end

  def unfollow
    current_user.unfollow(@user)
    redirect_back(fallback_location: root_url, notice: "Unfollowed #{@user.email}")
  end

  def following_users
    @following_users = current_user.following_users.page(params[:page])
  end

  def followers
    @followers = current_user.followers.page(params[:page])
    @following_user_ids = current_user.following_user_ids
  end

  private

  def user_params
    params.require(:user).permit(:email, :screen_name, :password)
  end

  def set_user
    @user = User.find(params[:user_id])
  end
end
