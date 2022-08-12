class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # :recoverable
  devise :database_authenticatable, :registerable,
         :rememberable, :validatable

  enum role: [:user, :moderator, :admin]

  after_initialize :set_default_role, if: :new_record?

  acts_as_voter

  has_many :posts
  has_many :comments
  has_many :follows
  has_many :communities, through: :follows

  validates :first_name, presence: true
  validates :last_name, presence: true

  def reputation
    result = 0
    self.get_voted(Post).each do |post|
      result += post.get_upvotes(vote_scope: 'reputation').sum(:vote_weight)
      result += post.get_downvotes(vote_scope: 'reputation').sum(:vote_weight)
    end
    result
  end

  def set_default_role
    self.role ||= :user
  end
end
