require 'net/http'
require 'json'

module HexFileProcessor
  class Program
    def self.main
      puts "Enter the path to the file: "
      file_path = gets.chomp

      if file_path.nil? || !File.exist?(file_path)
        puts "Invalid file path."
        return
      end

      fetch_hex_number_information(file_path)
    end

    def self.fetch_hex_number_information(file_path)
      api_url = "http://api.monni.moe/map?k="

      begin
        hex_numbers = File.readlines(file_path)
        fetched_info_file_path = File.join(File.dirname(__FILE__), "fetched_info.txt")

        hex_numbers.each do |hex_number|
          url = api_url + hex_number.chomp

          response = Net::HTTP.get_response(URI(url))

          if response.is_a?(Net::HTTPSuccess)
            response_body = response.body
            response_data = JSON.parse(response_body)

            if response_data && response_data['versions']
              max_version = response_data['versions'].max_by { |v| v['createdAt'] }

              if max_version
                fetched_info = []

                created_at = max_version['createdAt']
                metadata = response_data['metadata']

                fetched_info << "LevelAuthorName: #{metadata['levelAuthorName']}," if metadata && metadata['levelAuthorName']

                if fetched_info.any?
                  fetched_data = "#{hex_number.chomp}: Uploaded: #{created_at}, #{fetched_info.join(' ')}"

                  if File.exist?(fetched_info_file_path)
                    existing_lines = File.readlines(fetched_info_file_path)

                    index = existing_lines.index { |line| line.start_with?("#{hex_number.chomp}:") }

                    if index
                      existing_lines[index] = fetched_data
                    else
                      existing_lines << fetched_data
                    end

                    File.open(fetched_info_file_path, 'w') { |file| file.puts(existing_lines.sort) }
                  else
                    File.write(fetched_info_file_path, fetched_data + "\n")
                  end
                else
                  puts "No valid difficulty information found for hex number: #{hex_number.chomp}"
                end
              else
                puts "No diffs found for hex number: #{hex_number.chomp}"
              end
            else
              puts "No versions found for hex number: #{hex_number.chomp}"
            end
          else
            puts "Request failed: #{response.message}"
          end
        end

        puts "Fetched information saved successfully."
        puts "Process completed."
      rescue StandardError => e
        puts "Error: #{e.message}"
      end
    end
  end
end

HexFileProcessor::Program.main
