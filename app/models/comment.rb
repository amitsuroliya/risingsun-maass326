class Comment < ActiveRecord::Base

  validates :comment, :presence => true

  belongs_to :commentable, :polymorphic => true, :counter_cache => true
  belongs_to :blog
  belongs_to :profile

  default_scope :order => 'created_at ASC'
  scope :comments_without_self, lambda {|id| where('profiles.id != ? and commentable_type = ?',id, "Blog").joins(:profile)}
  scope :profile_comments, where("commentable_type='Profile'")
  scope :ordered, :order => 'created_at desc'

  include UserFeeds

  after_create :create_my_feed, :create_other_feeds

  def by_me?(profile)
    self.profile == profile
  end

  def on_my_profile?(profile)
    self.commentable == profile
  end

  def on_my_commentable?(profile)
    self.commentable && self.commentable.respond_to?(:profile) && (self.commentable.profile == profile)
  end

  def destroyable_by?(profile)
    by_me?(profile) or on_my_profile?(profile) or on_my_commentable?(profile)
  end

  def self.comments_on_object(obj)
    where(:commentable_id => obj, :commentable_type => obj.class.name)
  end

  def self.between_profiles profile1, profile2
    ordered.profile_comments.all({
        :conditions => ["(profile_id=? and commentable_id=?) or (profile_id=? and commentable_id=?)", profile1.id, profile2.id, profile2.id, profile1.id]
      })
  end

  def self.recent_comments(limit = 6)
    ordered.profile_comments.all(:limit => limit)
  end

end