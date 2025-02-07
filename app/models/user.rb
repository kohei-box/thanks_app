class User < ApplicationRecord
  has_many :active_relationships, class_name: "Relationship", foreign_key: "follower_id",
                                  dependent: :destroy
  has_many :passive_relationships, class_name: "Relationship", foreign_key: "followed_id",
                                   dependent: :destroy
  has_many :following, through: :active_relationships, source: :followed
  has_many :followers, through: :passive_relationships,source: :follower
  has_many :book_registrations, dependent: :destroy 
  has_many :books, through: :book_registrations
  has_many :reviews, dependent: :destroy
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :timeoutable, :omniauthable, omniauth_providers: [:twitter]
         
  validates :name, presence: true, length:{ maximum: 20 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, presence: true,
                    format:{with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }
  
  
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
    end
  end
  
  def follow(other_user)
    following << other_user
  end
  
  def unfollow(other_user)
    active_relationships.find_by(followed_id: other_user.id).destroy
  end
  
  def following?(other_user)
    following.include?(other_user)
  end
  
  def feed
    following_ids = "SELECT followed_id FROM relationships
                 WHERE follower_id = :user_id"
    Review.where("user_id IN (#{following_ids}) 
                  OR user_id = :user_id", user_id: id)
  end
  
end
