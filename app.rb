require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'
require 'slim'
require 'bcrypt'
enable :sessions

DB = SQLite3::Database.new 'db/data.db'

get('/home') do
  #id = session[:id].to_i
  #results = db.execute("SELECT * FROM maps WHERE id = ?",id) -------- Session management --------
  @processed_data = DB.execute("SELECT * FROM maps")


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

post '/upload' do
  unless params[:file] && (tmpfile = params[:file][:tempfile]) && (name = params[:file][:filename])
    return "No file selected"
  end

  target = "./uploads/#{name}"
  File.write(target, tmpfile.read)

  require_relative 'datafetcher.rb'
  File.delete("uploads/hex_numbers.txt")
  
  redirect '/home'
end