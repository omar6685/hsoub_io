class CommunitiesController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create]

  def new
    @community = Community.new
  end

  def create
    @community = Community.new(community_params)

    if @community.save
      redirect_to @community
    else
      render :new
    end
  end

  def index
    @communities = Community.all
  end

  def show
    @community = Community.find_by_id(params[:id])
    @posts = @community.posts
  end

  def follow
    @community = Community.find_by_id(params[:id])
    current_user.follows.create(community: @community)
    redirect_to @community, notice: 'قمت بمتابعة المجتمع بنجاح'
  end

  def unfollow
    @community = Community.find_by_id(params[:id])
    current_user.follows.where(community: @community).first.destroy
    redirect_to @community, notice: 'قمت بإلغاء متابعة المجتمع بنجاح'
  end

  private

  def community_params
    params.require(:community).permit(:name, :description)
  end
end
