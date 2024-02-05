require 'sinatra'
require 'sqlite3'
require 'slim'

# Connect to SQLite database
DB = SQLite3::Database.new 'db/maps.db'

# Route to handle the file upload form
get '/' do
  slim :index
end

# Route to handle the file upload submission
post '/upload' do
  unless params[:file] && (tmpfile = params[:file][:tempfile]) && (name = params[:file][:filename])
    return "No file selected"
  end

  target = "./uploads/#{name}"
  File.open(target, 'wb') { |f| f.write(tmpfile.read) }

  # Execute C# code
  `mono csharp_code/YourCSharpCode.exe #{target}`

  redirect '/result'
end

# Route to display the processed data
get '/result' do
  @processed_data = DB.execute("SELECT * FROM processed_data")
  slim :result
end
