require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'
require 'slim'
require 'bcrypt'
require 'time'
require_relative 'datafetcher.rb'

enable :sessions

DB = SQLite3::Database.new 'db/data.db'

#FIX RESTFULL AND EDIT FUNCTIONALITY FOR POSTS

get("/") do
  redirect '/home'
end 

post("/posts/new") do
  title = params[:title]
  content = params[:content]
  id = session[:id].to_i

  DB.execute("INSERT INTO posts (title, content) VALUES (?, ?)",title, content)
  DB.execute("INSERT INTO relation (post, userid) VALUES (?, ?)",title, id)

  redirect '/home'
end

post("/posts/edit") do
  newtitle = params[:newtitle]
  newcontent = params[:newcontent]
  id = session[:id].to_i

  DB.execute("UPDATE posts SET title = newtitle, content = newcontent WHERE ",newtitle, newcontent,title, content)
  DB.execute("INSERT INTO relation (post, userid) VALUES (?, ?)",title, id)

  redirect '/home'
end

post("/posts/delete") do
  post = params[:post]

  DB.execute("DELETE FROM posts WHERE title = ?", post)

  redirect "/home"
end

get("/post") do

  slim :"/posts/post"
end

get("/home") do
  id = session[:id].to_i
  user_map_list = DB.execute("SELECT mapid FROM relation WHERE userid = ?",id)
  
  user_map_info = []
  unix_age_filter = 0
  mapper_filter = params[:mapperFilterInput]
  age_filter = params[:ageFilterInput]
  unban_mapper = params[:unbanMapperInput]

  if mapper_filter || age_filter || unban_mapper
    if !age_filter.nil? && !age_filter.empty?
      parsed_date = DateTime.parse(age_filter&.to_s)
      unix_age_filter = parsed_date&.to_time&.to_i * 10
    end
    
    DB.execute("INSERT INTO relation (userid, mappername, agecap) VALUES (?, ?, ?)",id, mapper_filter, unix_age_filter)

    if !unban_mapper == ""
      DB.execute("DELETE FROM relation WHERE userid = ? AND mappername = ?",id, unban_mapper)
    end
  end

  user_map_list.each do |map_key|
    user_map_info << DB.execute("SELECT * FROM maps WHERE key = ? AND mapper != ? AND age > ?", map_key, mapper_filter, unix_age_filter)
  end

  @map_list = user_map_info
  @banned_mappers = DB.execute("SELECT mappername FROM relation WHERE userid = ?", id)
  @user = DB.execute("SELECT username FROM users WHERE id = ?", id)
  @posts = DB.execute("SELECT * FROM posts")
  slim :home
end

get("/register") do
  slim :register
end

post("/users/new") do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]
  
  if (password == password_confirm)
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new("db/data.db")
    db.execute("INSERT INTO users (username, pwdigest) VALUES (?, ?)",username, password_digest)
    redirect("/home")
    
  else
    "Lösenorden matchar inte"
  end
end

get("/showlogin") do
  slim :login
end

post("/login") do
  username = params[:username]
  password = params[:password]
  
  db = SQLite3::Database.new("db/data.db")
  db.results_as_hash = true
  
  result = db.execute("SELECT * FROM users WHERE username = ?",username).first
  pwdigest = result["pwdigest"]
  id = result["id"]
  
  if BCrypt::Password.new(pwdigest) == password
    session[:id] = id
    redirect("/home")
    
  else
    "Incorrect Password"
  end
end

get("/admin") do
  id = session[:id].to_i
  user = DB.execute("SELECT admin FROM users WHERE id = ?", id)
  
  if user != [[1]]
    redirect '/home'
  else
    @userlist = DB.execute("SELECT username FROM users")
  end

  slim :admin
end

post("/delete") do
  username = params[:username][2..-3]

  DB.execute("DELETE FROM users WHERE username = ?", username)

  redirect "/admin"
end

post("/upload") do
  unless params[:file] && (tmpfile = params[:file][:tempfile]) && (name = params[:file][:filename])
    return "No file selected"
  end

  target = "./uploads/#{name}"
  File.write(target, tmpfile.read)

  id = session[:id].to_i
  DB.execute("DELETE FROM relation WHERE userid = ?", id)
  processor = HexFileProcessor::Program.new
  processor.fetch_hex_number_information("./uploads/hex_numbers.txt", id)

  File.delete("uploads/hex_numbers.txt")

  redirect "/home"
end