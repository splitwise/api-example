class Post < ActiveRecord::Base
  attr_accessible :body, :user_id
  belongs_to :user
  after_create :add_default_post
end
