class User < ActiveRecord::Base
  attr_accessible :name
  has_many :posts

  def add_default_post
    self.posts << Post.new(body: "This is your first post.")
  end
end
