class LinksController < ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_moderator, only: [:edit, :update]

  def new
    @link = Link.new
  end

  def create
    @post = Post.new(post_params)
    @post.user_id = current_user.id
    if @post.save
      @link = Link.new(link_params)
      @link.post = @post
      if @link.save
        redirect_to @post
      else
        render :new
      end
    else
      @link.save
      render :new
    end
  end

  def edit
    @link = Link.find_by_id(params[:id])
  end

  def update
    @link = Link.find_by_id(params[:id])
    if @link.update(link_params)
      redirect_to @link.post
    else
      render :edit
    end
  end

  private

  def link_params
    params.require(:link).permit(:url)
  end

  def post_params
    params.require(:link).permit(:community_id, :title)
  end

  def authenticate_moderator
    redirect_to root_path, notice: t('not_authorized') unless current_user && current_user.moderator?
  end
end
