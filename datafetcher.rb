 require 'net/http'
 require 'sqlite3'
 require 'json'

 module HexFileProcessor
   class Program
     def self.fetch_hex_number_information(file_path)
       api_url = "http://api.monni.moe/map?k="

       db = SQLite3::Database.new 'db/maps.db'

       puts "Processing file: #{file_path}"

       begin
         hex_numbers = File.readlines(file_path)

         hex_numbers.each do |key|
           url = api_url + key.chomp

           response = Net::HTTP.get_response(URI(url))

           if response.is_a?(Net::HTTPSuccess)
             response_body = response.body
             response_data = JSON.parse(response_body)

             max_version = response_data['versions'].max_by { |v| v['createdAt'] }
             created_at = max_version['createdAt']
             metadata = response_data['metadata']
             level_author_name = metadata['levelAuthorName']

             db.execute("DELETE * FROM maps")
             db.execute("INSERT INTO maps (key, age, mapper) VALUES (?, ?, ?)", key.chomp, created_at, level_author_name)
           end
         end
       end
     end
   end
 end

 HexFileProcessor::Program.fetch_hex_number_information("./uploads/hex_numbers.txt")
