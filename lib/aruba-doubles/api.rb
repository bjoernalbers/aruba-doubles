require 'aruba-doubles/double'
require 'shellwords'

module ArubaDoubles
  module Api
    def doubled?
      !@doubles_dir.nil?
    end
    
    def create_double_by_cmd(cmd, options = {})
      arguments = Shellwords.split(cmd)
      filename = arguments.shift
      create_double(filename, arguments, options)
    end
    
    def create_double(filename, arguments, options = {})
      unless doubled?
        create_doubles_dir
        patch_original_path
      end   
      write_double(filename, get_double(filename, arguments, options))
    end
    
    def write_double(filename, double)
      fullpath = File.expand_path(filename, @doubles_dir)
      File.open(fullpath, 'w') do |f|
        f.puts "#!/usr/bin/env ruby"
        f.puts "# Doubled command line application by aruba-doubles\n"
        f.puts "require 'rubygems'"
        f.puts "require 'cucumber'"
        f.puts "require 'yaml'"
        f.puts "require 'aruba-doubles/double'"
        f.puts "ArubaDoubles::Double.run! YAML.load %Q{"
        f.puts double.expectations.to_yaml
        f.puts "}"
      end
      FileUtils.chmod(0755, fullpath)
    end

    def remove_doubles
      restore_original_path
      remove_doubles_dir
    end

  private

    def create_doubles_dir
      @doubles_dir = Dir.mktmpdir
    end
    
    def doubles
      @doubles ||= {}
    end

    def get_double(filename, arguments, options)
      doubles[filename] ||= ArubaDoubles::Double.new
      doubles[filename].could_receive(arguments, options)
    end

    def patch_original_path
      @__aruba_doubles_original_path = (ENV['PATH'] || '').split(File::PATH_SEPARATOR)
      ENV['PATH'] = ([@doubles_dir] + @__aruba_doubles_original_path).join(File::PATH_SEPARATOR)
    end

    def restore_original_path
      ENV['PATH'] = @__aruba_doubles_original_path.join(File::PATH_SEPARATOR) unless doubled?
    end

    def remove_doubles_dir
      FileUtils.rm_r(@doubles_dir) unless @doubles_dir.nil?
    end
  end
end
