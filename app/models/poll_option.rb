class PollOption < ActiveRecord::Base
  
  belongs_to :poll
  has_many :poll_responses, :dependent => :destroy

  validates :option, :length=> {:maximum => 25}

  def votes_percentage(precision = 1)
    total_votes = poll.poll_responses.count
    percentage = total_votes.eql?(0) ? 0 : ((poll_responses.count.to_f/total_votes.to_f)*100)
    "%01.#{precision}f" % percentage
  end

end