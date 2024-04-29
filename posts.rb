class PostsApp < Sinatra::Base
  set :posts, []

  def add_post(title, content)
    @settings.posts << { title: title, content: content }
  end

  def find_post(id)
    @settings.posts[id.to_i]
  end

  def update_post(id, title, content)
    @settings.posts[id.to_i] = { title: title, content: content }
  end

  def delete_post(id)
    @settings.posts.delete_at(id.to_i)
  end
end
