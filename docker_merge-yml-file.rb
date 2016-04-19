require 'yaml'

if (ARGV.length != 2)
	puts 'expected exactly 2 params (filenames) to merge; got ' + ARGV.length.to_s
	exit 1
end

first_file = ARGV[0]
second_file = ARGV[1]
settings = YAML.load_file(first_file)
settings2 = YAML.load_file(second_file)
merged_settings=settings.merge(settings2)
puts merged_settings.to_yaml[3...-1]
