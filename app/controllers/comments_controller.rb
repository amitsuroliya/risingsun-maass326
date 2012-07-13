class CommentsController < ApplicationController

  before_filter :load_profile, :only=>[:index]
  respond_to :html, :json, :only =>[:destroy]

  def index
    @comments = Comment.between_profiles(@p, @profile).paginate(:page => @page, :per_page => @per_page)
    redirect_to @p and return if @p == @profile
  end

  def create    
    @comment = @p.profile_comments.create(params[:comment])
    if @comment.save
      if @comment.commentable_type == "Blog"
        @blog = @comment.commentable
        @profile = @blog.profile
        ArNotifier.delay.comment_send_on_blog(@comment,@profile,@p) if @profile.wants_email_notification?("blog_comment")
        @blog.commented_users(@p.id).each do |comment|
          ArNotifier.delay.comment_send_on_blog_to_others(@comment,comment.profile,@p,@blog.profile) if comment.profile.wants_email_notification?("blog_comment")
        end
      elsif @comment.commentable_type == "Profile"
        @profile= @comment.commentable
        ArNotifier.delay.comment_send_on_profile(@comment,@profile,@p) if @profile.wants_email_notification?("profile_comment")
      end
      flash[:notice] = "Comment created successfully."
      redirect_to request.referer
    else
      flash[:error] = "Comment not created successfully."
      redirect_to request.referer
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy
    flash[:notice] = "Successfully destroyed comment."
    comment_count = @comment.commentable.comments_count - 1
    respond_with((comment_count > 1 ? "#{comment_count} Comments" : "#{comment_count} Comment").to_json)
  end

  private

  def load_profile        
    @profile = params[:profile_id] == @p ? @p : Profile.find(params[:profile_id])
    @show_profile_side_panel = true
  end
  
end