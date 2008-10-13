require 'rubygems'
require 'activerecord'
require File.dirname(__FILE__) + '/../lib/yaml_db'

class CommandLine
	class LocationDoesntExists < RuntimeError; end
	class ConfigNotFound       < RuntimeError; end
	class InvalidUsage         < RuntimeError; end

	def self.run(args)
		new(args).run
	rescue LocationDoesntExists
		puts "The specified location doesn't exists"
	rescue ConfigNotFound
		puts "Could not connect to your database via ActiveRecord"
		puts "Run in the root of your Rails app or set db access in ENV"
	rescue InvalidUsage
		puts "Usage: yamldb [optional app path] dump [path. if omitted will dump to STDOUT]"
		puts "       yamldb [optional app path] load [path]"
	ensure
		ActiveRecord::Base.connection.disconnect! rescue nil
	end

	attr_accessor :args, :location
	def initialize(args=[])
		@args = args
		@location = parse_location
	end

	def commands
		%w( dump load )
	end

	def env
		@env ||= ENV['RAILS_ENV'] || ENV['APP_ENV'] || 'development'
	end

	def parse_location
		return Dir.pwd unless args[0] && !commands.include?(args[0].downcase)
		location = args.shift
		raise LocationDoesntExists unless File.exists?(location)
		location
	end

	def config
		return @config if @config

		@config = config_from_env || config_from_file(location)
		raise ConfigNotFound unless @config
		ActiveRecord::Base.configurations[env] = @config
		return @config
	end

	def run
		parse_location
		raise InvalidUsage unless args[0] && commands.include?(args[0].downcase)
		command = args.shift.to_sym

		filename = args.shift if args[0]
		if command == :dump
			io = filename ? File.new(filename, 'w') : STDOUT
		else
			io = File.new(filename, 'r') if filename
		end
		raise InvalidUsage unless io

		ActiveRecord::Base.establish_connection(config)
		YamlDb.send(command, env, io)
	end

	def config_from_env
		return unless ENV['ADAPTER']
		{
			'adapter'  => ENV['ADAPTER'],
			'host'     => ENV['HOST'] || 'localhost',
			'database' => ENV['DATABASE'],
			'username' => ENV['ROLE'] || ENV['USERNAME'],
			'password' => ENV['PASSWORD'] || '',
		}
	end

	def config_from_file(original_location)
		location = original_location.gsub(/\/$/, '')
		return unless File.exists?(location)
		if location =~ /database.yml$/
			require 'yaml'
			return YAML::load(File.open(location))[env]
		else # attempt to guess where's database.yml
			config_from_file("#{location}/config/database.yml") || config_from_file("#{location}/database.yml")
		end
	end
end