class Admin::HomeController < ApplicationController

  layout "admin"

  before_filter :load_profile

  authorize_resource :class=> false

  def index
  end

  def blogs
    @blogs = @profile.sent_blogs
  end

  def send_blog
    blog = Blog.find(params[:id])
    blog.update_attribute(:is_sent,true)
    @profiles = Profile.active_profiles
    admin_sender = Profile.admins.first
    @profiles.each do|profile|
      ArNotifier.delay.sent_news(blog,profile) if profile.wants_email_notification?("news")
      if profile.wants_message_notification?("news")
        admin_sender.sent_messages.create(
          :subject => "[#{SITE_NAME} News] #{blog.title} by #{blog.sent_by}",
          :body => blog.body,
          :receiver => profile,
          :system_message => true)
      end
    end
    TweetsWorker.send_blog_tweets(blog.id)
    redirect_to :back
    flash[:notice] = "Blog was successfully sent"
  end

  def google_map_locations
    @markers = Marker.all
    profiles = @p.friends_on_google_map
    @friends = profiles.select{|p| p.marker}
  end

  
  private
  
  def load_profile
    @profile = @p
  end

end