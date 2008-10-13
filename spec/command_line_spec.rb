require File.dirname(__FILE__) + '/base'

describe CommandLine do
	context "location" do
		before do
			Dir.stub!(:pwd).and_return('/apps/myapp')
		end

		it "uses the current location as default" do
			CommandLine.new.location.should == '/apps/myapp'
		end

		it "doesn't attempt to get locations from commands" do
			CommandLine.new(['dump']).location.should == '/apps/myapp'
			CommandLine.new(['load']).location.should == '/apps/myapp'
		end

		it "accepts a location as the first argument, checking if it exists" do
			File.should_receive(:exists?).with('/home/myapp').and_return(true)
			CommandLine.new(['/home/myapp']).location.should == '/home/myapp'
		end

		it "raises when the location doesn't exists" do
			File.stub!(:exists?).with('/wrongpath').and_return(false)
			lambda { CommandLine.new(['/wrongpath']) }.should raise_error(CommandLine::LocationDoesntExists)
		end
	end

	context "db config" do
		before(:all) do
			@sandbox = Rush::Box.new['/tmp/yaml_db_spec/']
			@sandbox.destroy
			@sandbox.create
			@sandbox['config/'].create
			@sandbox['config/database.yml'].write "development:\n  database: myapp"
		end

		before(:each) do
			@c = CommandLine.new
		end

		it "attempts to parse from ENV vars first" do
			@c.should_receive(:config_from_env).and_return(:env_database_config)
			@c.config.should == :env_database_config
		end

		it "then attempts to parse from database.yml" do
			@c.should_receive(:config_from_env).and_return(nil)
			@c.should_receive(:config_from_file).and_return(:database_yml_config)
			@c.config.should == :database_yml_config
		end

		it "raises when there's no config" do
			@c.should_receive(:config_from_env).and_return(nil)
			@c.should_receive(:config_from_file).and_return(nil)
			lambda { @c.config }.should raise_error(CommandLine::ConfigNotFound)
		end

		it "goes straight to database.yml when informed as the location" do
			CommandLine.new([@sandbox['config/database.yml'].full_path]).config.should == { 'database' => 'myapp'}
		end

		it "attempts to guess where is database.yml when location is a folder" do
			CommandLine.new([@sandbox['config/'].full_path]).config.should == { 'database' => 'myapp'}
			CommandLine.new([@sandbox.full_path]).config.should == { 'database' => 'myapp'}
		end
	end

	context "execution" do
		before do
			@c = CommandLine.new
			@c.stub!(:config).and_return('database' => 'myapp')
			@file = mock('file handler')
		end

		it "requires one input file when loading" do
			@c.args = ['load']
			lambda { @c.run }.should raise_error(CommandLine::InvalidUsage)
		end

		it "loads from the specified file" do
			@c.args = ['load', 'mydump.yml']
			ActiveRecord::Base.should_receive(:establish_connection)
			File.should_receive(:new).with('mydump.yml', 'r').and_return(@file)
			YamlDb.should_receive(:load).with('development', @file)
			@c.run
		end

		it "dumps to stdout when there's no output argument" do
			@c.args = ['dump']
			ActiveRecord::Base.should_receive(:establish_connection)
			YamlDb.should_receive(:dump).with('development', STDOUT)
			@c.run
		end

		it "dumps to a file when specified" do
			@c.args = ['dump', 'mydump.yml']
			ActiveRecord::Base.should_receive(:establish_connection)
			File.should_receive(:new).with('mydump.yml', 'w').and_return(@file)
			YamlDb.should_receive(:dump).with('development', @file)
			@c.run
		end
	end
end