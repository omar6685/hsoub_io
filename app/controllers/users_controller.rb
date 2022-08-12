class UsersController < ApplicationController
  def show
    @user = User.find_by_id(params[:id])
    @posts = @user.posts
  end
end
