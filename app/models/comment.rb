class Comment < ApplicationRecord
    has_ancestry
  
    belongs_to :user
    belongs_to :post
  
    validates :text, presence: true
  
    after_commit :create_notifications, on: [:create]
  
    def create_notifications
      Notification.create(
        notify_type: 'comment',
        actor: self.user,
        user: self.post.user,
        target: self
      )
    end
  end
  