require 'json'
require 'net/http'
require 'uri'
require 'set'
require 'optparse'

BUILTIN_MODS = Set.new(["base", "quality", "elevated-rails", "space-age"])
local_mod = nil

def is_required_dependency(dep_str)
  return false if (dep_str.start_with?("?") || dep_str.start_with?("!") || dep_str.start_with?("(?)"))
  return true
end

def parse_dependency_name(dep_str)
  return nil if dep_str.nil? || dep_str.strip.empty? or not is_required_dependency(dep_str.strip)
  return dep_str.strip.split(/\s+/).first
end

options = {
  mod_list: "mod-list.json",
  info_file: nil,
  output: nil
}

OptionParser.new do |opts|
  opts.banner = "Usage: ruby expand_dependencies.rb -m mod-list.json [-i info.json] [-o output.json]"

  opts.on("-m", "--mod-list FILE", "Input mod-list.json file") do |v|
    options[:mod_list] = v
  end

  opts.on("-i", "--info FILE", "Mod's info.json file ") do |v|
    options[:info_file] = v
  end

  opts.on("-o", "--output FILE", "Output mod-list.json (default: overwrite input)") do |v|
    options[:output] = v
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

input_file = options[:mod_list]
info_file = options[:info_file]
output_file = options[:output]

unless File.exist?(input_file)
  puts "Error: Input file '#{input_file}' not found."
  exit 1
end

unless info_file.nil? or File.exist?(info_file)
  puts "Error: Info file '#{info_file}' not found."
  exit 1
end

enabled_set = Set.new
fetched = Set.new

if info_file
  begin
    local_mod_info = JSON.parse(File.read(info_file))
    local_mod = local_mod_info["name"]
    enabled_set << local_mod
    local_mod_info["dependencies"].each do |dep|
      parsed_dep = parse_dependency_name(dep)
      next if parsed_dep.nil? || parsed_dep.empty?
      enabled_set << parsed_dep
    end
  end
end

data = JSON.parse(File.read(input_file))
mods_array = data["mods"] || []

mods_array.each do |mod_entry|
  if mod_entry["enabled"] == true || mod_entry["enabled"].to_s.downcase == "true"
    parsed_mod = parse_dependency_name(mod_entry["name"])
    next if parsed_mod.nil? || parsed_mod.empty?
    enabled_set << parsed_mod
  end
end

to_fetch = enabled_set.reject { |name| local_mod == name or BUILTIN_MODS.include?(name) }.to_a

while !to_fetch.empty?
  new_deps = Set.new

  to_fetch.each do |raw_mod_name|
    mod_name = parse_dependency_name(raw_mod_name)
    next if fetched.include?(mod_name)

    fetched << mod_name

    uri = URI("https://mods.factorio.com/api/mods/#{mod_name}/full")
    begin
      response = Net::HTTP.get_response(uri)
      if response.code != "200"
        puts "Warning: HTTP #{response.code} for #{mod_name}"
        next
      end

      mod_data = JSON.parse(response.body)

      deps = []
      if mod_data["releases"] && !mod_data["releases"].empty?
        latest = mod_data["releases"].max_by { |r| r["version"] || "" }
        deps = latest.dig("info_json", "dependencies") || [] if latest
      end

      deps.each do |dep_str|
        parsed_dep = parse_dependency_name(dep_str)
        next if parsed_dep.nil? || parsed_dep.empty?
        unless enabled_set.include?(parsed_dep)
          new_deps << parsed_dep
          enabled_set << parsed_dep
        end
      end

    rescue => e
      puts "    Error fetching #{mod_name}: #{e.message}"
    end
  end
  to_fetch = new_deps.reject { |name| local_mod == name or BUILTIN_MODS.include?(name) }.to_a
end


final_mods = []
enabled_set.each { |name| final_mods << { "name" => name, "enabled" => true } }

if output_file
  File.write(output_file, JSON.pretty_generate({ "mods" => final_mods }))
  puts "Wrote to '#{output_file}'"
else
  puts JSON.pretty_generate({ "mods" => final_mods })
end