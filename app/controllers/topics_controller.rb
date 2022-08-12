class TopicsController < ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_moderator, only: [:edit, :update]

  def new
    @topic = Topic.new
  end

  def create
    @post = Post.new(post_params)
    @post.user_id = current_user.id
    if @post.save
      @topic = Topic.new(topic_params)
      @topic.post = @post
      if @topic.save
        redirect_to @post
      else
        render :new
      end
    else
      @topic.save
      render :new
    end
  end

  def edit
    @topic = Topic.find_by_id(params[:id])
  end

  def update
    @topic = Topic.find_by_id(params[:id])
    if @topic.update(topic_params)
      redirect_to @topic.post
    else
      render :edit
    end
  end

  private

  def topic_params
    params.require(:topic).permit(:text)
  end

  def post_params
    params.require(:topic).permit(:community_id, :title)
  end

  def authenticate_moderator
    redirect_to root_path, notice: t('not_authorized') unless current_user && current_user.moderator?
  end
end
