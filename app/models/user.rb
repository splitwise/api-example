class User < ActiveRecord::Base
  attr_accessible :name
  has_many :posts
  after_create :add_default_post

  def add_default_post
    self.posts << Post.new(body: "This is your first post.")
  end
end
