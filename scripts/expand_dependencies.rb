require 'json'
require 'net/http'
require 'uri'
require 'set'

BUILTIN_MODS = Set.new(["base", "quality", "elevated-rails", "space-age"])

def is_required_dependency(dep_str)
  return false if dep_str.nil? || dep_str.strip.empty?

  s = dep_str.strip
  return not (s.start_with?("?") || s.start_with?("!") || s.start_with?("(?)"))
end

def parse_dependency_name(dep_str)
  return nil if dep_str.nil? || dep_str.strip.empty?
  return dep_str.strip.split(/\s+/).first
end

# ====================== Main script ======================

input_file = ARGV[0] || "mod-list.json"
# TODO: include info.json for mod being tested!

unless File.exist?(input_file)
  puts "Error: Input file '#{input_file}' not found."
  exit 1
end

data = JSON.parse(File.read(input_file))
mods_array = data["mods"] || []

enabled_set = Set.new
mods_array.each do |mod_entry|
  if mod_entry["enabled"] == true || mod_entry["enabled"].to_s.downcase == "true"
    name = mod_entry["name"]&.strip
    next if name.nil? || name.empty?
    enabled_set << name
  end
end

to_fetch = enabled_set.reject { |name| BUILTIN_MODS.include?(name) }.to_a

iteration = 0
while !to_fetch.empty?
  iteration += 1
  new_deps = Set.new

  to_fetch.each do |mod_name|
    next if enabled_set.include?(mod_name)

    puts "  Fetching #{mod_name}..."

    uri = URI("https://mods.factorio.com/api/mods/#{mod_name}/full")

    begin
      response = Net::HTTP.get_response(uri)
      if response.code != "200"
        puts "    Warning: HTTP #{response.code} for #{mod_name}"
        fetched << mod_name
        next
      end

      mod_data = JSON.parse(response.body)

      deps = []
      if mod_data.dig("latest_release", "info_json", "dependencies")
        deps = mod_data["latest_release"]["info_json"]["dependencies"]
      elsif mod_data["releases"] && !mod_data["releases"].empty?
        latest = mod_data["releases"].max_by { |r| r["version"] || "" }
        deps = latest.dig("info_json", "dependencies") || [] if latest
      end

      deps.each do |dep_str|
        next unless is_required_dependency(dep_str)

        dep_name = parse_dependency_name(dep_str)
        next if dep_name.nil? || dep_name.empty?

        unless all_mods.include?(dep_name)
          new_deps << dep_name
        end
      end

      fetched << mod_name
    rescue => e
      puts "    Error fetching #{mod_name}: #{e.message}"
      fetched << mod_name
    end
  end

  if new_deps.empty?
    to_fetch = []
  else
    all_mods.merge(new_deps)
    to_fetch = new_deps.reject { |name| BUILTIN_MODS.include?(name) }.to_a
    puts "  Added #{new_deps.size} new required dependencies (iteration #{iteration})"
  end
end

puts "\nTotal mods after resolution: #{all_mods.size}"

# Build final list
final_mods = []
original_enabled.each { |name| final_mods << { "name" => name, "enabled" => true } }

added = (all_mods - Set.new(original_enabled)).sort
added.each { |name| final_mods << { "name" => name, "enabled" => true } }

# Overwrite original file
File.write(input_file, JSON.pretty_generate({ "mods" => final_mods }))

puts "✅ Done! Overwrote '#{input_file}'"
puts "   #{final_mods.size} mods total (backup: #{backup_file})"