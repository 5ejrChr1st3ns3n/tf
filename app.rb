require 'sinatra'
require 'sqlite3'
require 'slim'
require 'bcrypt'

DB = SQLite3::Database.new 'db/maps.db'

get '/' do

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
    db = SQLite3::Database.new("db/users.db")
    db.execute("INSERT INTO users (username, pwdigest) VALUES (?, ?)",username, password_digest)
    redirect("/")
    
  else
    "Lösenorden matchar inte"
  end
end

post("/login") do
  username = params[:username]
  password = params[:password]
  
  db = SQLite3::Database.new("db/users.db")
  db.results_as_hash = true
  
  result = db.execute("SELECT * FROM users WHERE userame = ?, username").first
  pwdigest = result["pwdigest"]
  id = result["id"]
  
  if BCrypt::Password.new(pwdigest) == password
    redirect("/home")
    
  else
    "Incorrect Password"
  end

  # Route to handle the file upload form
  get '/home' do
    @processed_data = DB.execute("SELECT * FROM maps")

    slim :index
  end
  
  # Route to handle the file upload submission
  post '/upload' do
    unless params[:file] && (tmpfile = params[:file][:tempfile]) && (name = params[:file][:filename])
      return "No file selected"
    end
  
    target = "./uploads/#{name}"
    File.open(target, 'wb') { |f| f.write(tmpfile.read) }
    #File.write(target, tmpfile.read)
  
    require_relative 'datafetcher.rb'
    
    redirect '/home'
  end
end