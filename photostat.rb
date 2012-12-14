#!/usr/bin/env ruby


begin
	require 'rubygems'
rescue LoadError => error
	puts error
	abort "Please install ruby gem rubygems"
end

begin
	require 'exifr'
rescue LoadError => error
	puts error
	abort "Please install ruby gem exifr"
end

begin
	require 'optparse'
rescue LoadError => error
	puts error
	abort "Please install ruby gem optparse"
end

begin
	require 'ostruct'
rescue LoadError => error
	puts error
	abort "Please install ruby gem ostruct"
end

begin
	require 'csv'
rescue LoadError => error
	puts error
	abort "Please install ruby gem csv"
end

#require 'pp' # for debuging


VERSION =  "Photostat ver 0.1"
DELIMITER = ","
FIELDSEP = "\""


class Photostat
  attr_accessor :images_list, :output_filename, :working_direcotry, :current_directory, :options

  class Exif 
    METTERING_MODES = %w{unknown Average CenterWeightedAverage Spot Multispot Pattern Partial}
    EXPOSURE_PROGRAMS = %w{unknown M P A S CreativeProgram ActionProgram PortraitMode LandscapeMode}
    EXPOSURE_MODES = %w{AutoExposure ManualExposure AutoBracket}
    WHITE_BALANCES = %w{AutoWB ManualWB}
    SUBJECT_DISTANCE_RANGES = %w{unknown Macro Close Distant}
    LIGHT_SOURCES = %w{unknown Daylight Fluorescent Tungsten Flash SunnyWeather CloudyWeather Shade DaylightFluorescent DaywhiteFluorescent CoolwhiteFluorescent WhiteFluorescent StandardLightA StandardLightB StandardLightC D55 D65 D75 D50 ISOstudioTungsten }

    attr_accessor :exifdata
    attr_accessor :image_filename
   
    def get_exif(file)
      @exifdata = Hash.new
      exif = EXIFR::JPEG.new(file)
      if exif.exif? 
        @exifdata[:file] = file
        @exifdata[:date] = exif.date_time_original.strftime("%d.%m.%Y") if exif.date_time_original
        @exifdata[:time] = exif.date_time_original.strftime("%k:%M") if exif.date_time_original
        @exifdata[:manufactor] = exif.make
        @exifdata[:model] = exif.model 
        @exifdata[:exposure_program] = EXPOSURE_PROGRAMS[exif.exposure_program] if exif.exposure_program
        @exifdata[:f_number] = exif.f_number.to_f
        @exifdata[:exposure_time] = exif.exposure_time.to_s 
        @exifdata[:exposure_bias] = exif.exposure_bias_value
        @exifdata[:iso] = exif.iso_speed_ratings
        @exifdata[:focal_lenght_35eq] = exif.focal_length_in_35mm_film
        @exifdata[:metering_mode] = METTERING_MODES[exif.metering_mode] if exif.metering_mode
        @exifdata[:white_balance] = WHITE_BALANCES[exif.white_balance] if exif.white_balance
        @exifdata[:light_source] = LIGHT_SOURCES[exif.light_source] if exif.light_source
      else
        exifdata = nil
      end #if
    end #end get_exif
  end # end class Exif 

  class Options 
    def self.parse(args)
      options = OpenStruct.new
        options.input_dir = "."
        options.output_filename = "" 
        options.verbose = false
        options.dir_recursive = false

      opts = OptionParser.new do |opts|
        opts.banner = "Usage: photostat.rb [options]"

        opts.separator ""
        opts.separator "Specific options:"

        opts.on("-o", "--output FILENAME", "Require the filename to write") do |outfile|
          options.output_filename = outfile
        end
        opts.on("-d", "--directory DIRECTORY", "Specify directory of photos. (default this directory)") do |dir|
          options.input_dir = dir
        end
        opts.on("-v", "--verbose", "Run verbosely") do |v|
          options.verbose = v
        end
        opts.on("-r", "--recursive", "Make list with all files in all directories in specified directory") do |r|
          options.dir_recursive = r
        end

        opts.separator ""
        opts.separator "Common options:"

        # No argument, shows at tail.  This will print an options summary.
        opts.on_tail("-h", "--help", "Show this message") do
          puts "This is a script for creating a list of EXIF values from photos."
          puts "You must specify output filename. This script will write some photographic values from photos"
          puts "\n"
          puts opts
          exit
        end

        opts.on_tail("--version", "Show version") do
          puts VERSION
          exit
        end
      end # end opts

      opts.parse!(args)

      if options.output_filename.empty? 
        puts opts
        puts "\n\n ERROR: Output filename must be specified. Please specify -o parameter"
        exit 1
      end

     options

    end #end parse
  end  # end class Options

  def initialize # Photostat 
    @options = Options.parse(ARGV)
    @output_filename = File.expand_path(options.output_filename)

    @current_directory = Dir.pwd
    begin
      @working_directory = Dir.chdir(options.input_dir)
    rescue Errno::ENOENT => err
      puts "Error: #{err.message}"
      exit 1
    end

    unless options.dir_recursive 
      images = File.join("*.{jpg,jpeg,JPG}")
      else
      images = File.join("**", "*.{jpg,jpeg,JPG}") 
    end
    @images_list = Dir.glob(images)
    puts "No photos in spedified directory: #{options.input_dir}" if @images_list.empty? 
  end

  def save_csv
# Protection of hard overwrite of output filename
#      if File.exist?(@output_filename) then
#        puts "Filename exist: #{@output_filename}. Please select other filename"
#        exit 1
#      end

      begin
        csv_file = CSV.open(@output_filename, "wb", :col_sep => ',' ) 
      rescue Errno::EACCES => err 
        puts "ERROR: #{err.message}" 
        exit 1
      end
      firstline = true
      images_list.each do |file|
        puts "Reading exif from #{file}" if options.verbose
        image = Exif.new(file)
        image.get_exif(file)
        csv_file << image.exifdata.keys if firstline   #header
        csv_file << image.exifdata.values
        firstline = false
      end
      csv_file.close
  end
  
  photostat = Photostat.new
  photostat.save_csv
end
