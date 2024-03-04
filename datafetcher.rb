# require 'net/http'
# require 'json'

# module HexFileProcessor
#   class Program
#     def self.main(file_path)
#       if file_path.nil? || !File.exist?(file_path)
#         puts "Invalid file path."
#         return
#       end

#       fetch_hex_number_information(file_path)
#     end

#     def self.fetch_hex_number_information(file_path)
#       api_url = "http://api.monni.moe/map?k="

#       puts "Processing file: #{file_path}"

#       begin
#         hex_numbers = File.readlines(file_path)
#         fetched_info_file_path = File.join(File.dirname(__FILE__), "fetched_info.txt")

#         hex_numbers.each do |hex_number|
#           url = api_url + hex_number.chomp

#           response = Net::HTTP.get_response(URI(url))

#           if response.is_a?(Net::HTTPSuccess)
#             response_body = response.body
#             response_data = JSON.parse(response_body)

#             if response_data && response_data['versions']
#               max_version = response_data['versions'].max_by { |v| v['createdAt'] }

#               if max_version
#                 fetched_info = []

#                 created_at = max_version['createdAt']
#                 metadata = response_data['metadata']

#                 fetched_info << "LevelAuthorName: #{metadata['levelAuthorName']}," if metadata && metadata['levelAuthorName']

#                 # Assuming hex_code contains the hex code you want to insert
#                 db.execute("INSERT INTO hex_data (hex_code) VALUES (?)", [hex_code])
#                 # ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#                 # ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ LOOOK AT IIIIIT
#               end
#             end
#           end
#         end
#       end
#     end
#   end
# end

# HexFileProcessor::Program.main("./uploads/hex_numbers.txt")
