class CommentsController < ApplicationController
  before_action :authenticate_user!

  def new
    @post = Post.friendly.find(params[:post_id])
    @comment = Comment.find_by_id(params[:parent_id])
  end

  def create
    @post = Post.friendly.find(params[:post_id])
    @comment = @post.comments.new(comment_params)
    @comment.ancestry = params[:comment][:parent_id]
    @comment.user_id = current_user.id
    if @comment.save
      redirect_to post_path(@post)
      flash[:notice] = t('comment.create.success')
    else
      redirect_to post_path(@post)
      flash[:notice] = @comment.errors.messages.values[0]
    end
  end

  def user_comments
    @user = User.find_by_id(params[:u_id])
    @comments = @user.comments.where(ancestry: nil)
  end

  private

  def comment_params
    params.require(:comment).permit(:text)
  end
end
