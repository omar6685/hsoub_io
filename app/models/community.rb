class Community < ApplicationRecord
    has_many :posts
    has_many :follows
    has_many :users, through: :follows

    validates :name, presence: true
    validates :description, presence: true
end
