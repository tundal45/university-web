class Assignment::Submission < ActiveRecord::Base
  belongs_to :status, :class_name  => "::SubmissionStatus", 
                      :foreign_key => "submission_status_id"
                      
  belongs_to :user
  belongs_to :assignment
  
  # TODO Remove after server data migration
  has_many :reviews,  :dependent => :delete_all
  
  has_many :comments,   :as => :commentable, :dependent => :delete_all
  has_many :activities, :dependent => :delete_all
  
  def create_comment(comment_data)
    comment = comments.create(comment_data)
    
    activities.create(
      :user_id       => comment.user.id,
      :description   => "made a comment",
      :context       => ActivityHelper.context_snippet(comment.comment_text),
      :actionable    => comment
    )
    
    UserMailer.submission_comment_created(comment).deliver
  end
  
  def update_status(user, new_status)
    activity = activities.create(
      :user_id     => user.id,
      :description => "updated status",
      :context     => "Updated status from *#{self.status.name}* to " +
                      "*#{new_status.name}*",
      :actionable  => self
    )
    
    update_attribute(:submission_status_id, new_status.id)
    
    UserMailer.submission_updated(activity).deliver
  end
  
  def update_description(user, new_description)
    activity = activities.create(
      :user_id     => user.id,
      :description => "updated description",
      :actionable  => self
    )
    
    send_email = description.blank?
    
    update_attribute(:description, new_description)
    
    UserMailer.submission_updated(activity).deliver if send_email
  end
  
  def editable_by?(user)
    assignment.course.instructors.include?(user) or self.user == user
  end
  
  def last_active_on
    if activities.any?
      activities.last.created_at
    else
      updated_at
    end
  end
end
