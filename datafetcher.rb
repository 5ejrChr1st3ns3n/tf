 require 'net/http'
 require 'sqlite3'
 require 'json'
 enable :sessions

 module HexFileProcessor
  class Program
    def fetch_hex_number_information(file_path, id)
      api_url = "http://api.monni.moe/map?k="
      db = SQLite3::Database.new 'db/data.db'
      
      begin
        hex_numbers = File.readlines(file_path).map(&:chomp)

        hex_numbers.each do |hex_number|
          db.execute("INSERT INTO relation (userid, mapid) VALUES (?, ?)", id, hex_number)
        end

        keys = db.execute("SELECT key FROM maps").map(&:first)
        remaining_hex_numbers = hex_numbers - keys

        remaining_hex_numbers.each do |key|
          url = api_url + key

          response = Net::HTTP.get_response(URI(url))

          if response.is_a?(Net::HTTPSuccess)
            response_body = response.body
            response_data = JSON.parse(response_body)

            max_version = response_data['versions'].max_by { |v| v['createdAt'] }
            created_at = max_version['createdAt']
            metadata = response_data['metadata']
            level_author_name = metadata['levelAuthorName']

            db.execute("INSERT or IGNORE INTO maps (key, age, mapper) VALUES (?, ?, ?)", key, created_at, level_author_name)
          end
        end
      end
    end
  end
end