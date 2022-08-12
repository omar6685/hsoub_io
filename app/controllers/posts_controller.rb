class PostsController < ApplicationController
  def vote
    value = params[:type]
    @post = Post.friendly.find(params[:id])
    if value == 'up'
      @post.vote_by voter: current_user, vote: 'like', vote_scope: 'reputation', vote_weight: 1
    else
      @post.vote_by voter: current_user, vote: 'dislike', vote_scope: 'reputation', vote_weight: -1
    end
    redirect_to @post, notice: t('voting_thanks')
  end

  def index
    @posts = Post.search(params[:search])
  end

  def show
    @post = Post.friendly.find(params[:id])
    @comment = Comment.new
  end
end
