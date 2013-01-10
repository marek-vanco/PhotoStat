#!/usr/bin/env ruby

# This is a script for creating a list of EXIF values from photos.
# You must specify output filename. This script will create a .csv file with EXIF values:
# 
# This script is under GNU software licence.
#
# Author: alpyapple@gmail.com
# source: git://github.com/marek-vanco/PhotoStat.git

begin
	require 'rubygems'
rescue LoadError => error
	puts error
	abort "Please install gem install rubygems"
end

begin
	require 'exifr'
rescue LoadError => error
	puts error
	abort "Please install gem install exifr"
end

begin
	require 'optparse'
rescue LoadError => error
	puts error
	abort "Please install gem install optparse"
end

begin
	require 'ostruct'
rescue LoadError => error
	puts error
	abort "Please install gem install ostruct"
end

begin
	require 'csv'
rescue LoadError => error
	puts error
	abort "Please install gem install csv"
end

require 'pp' # for debuging 

VERSION =  "Photostat ver 0.3"
DELIMITER = ","
FIELDSEP = "\""

class Photostat

  class Exif 
    METTERING_MODES = %w{unknown Average CenterWeightedAverage Spot Multispot Pattern Partial}
    EXPOSURE_PROGRAMS = %w{unknown M P A S CreativeProgram ActionProgram PortraitMode LandscapeMode}
    EXPOSURE_MODES = %w{AutoExposure ManualExposure AutoBracket}
    WHITE_BALANCES = %w{AutoWB ManualWB}
    SUBJECT_DISTANCE_RANGES = %w{unknown Macro Close Distant}
    LIGHT_SOURCES = %w{unknown Daylight Fluorescent Tungsten Flash SunnyWeather CloudyWeather Shade DaylightFluorescent DaywhiteFluorescent CoolwhiteFluorescent WhiteFluorescent StandardLightA StandardLightB StandardLightC D55 D65 D75 D50 ISOstudioTungsten }
    ORIENTATION = %w{TopLeft TopRight BottomRigth BottomLeft LeftTop RightTop RightBottom LeftBottom} # todo verify values
		COLOR_SPACE = %w{AdobeRGB sRGB RAW} # todo: verify values
		SENSING_METHOD = %w{AF-A AF-S AF-C} # todo: verify values

    def get_exif(file)
      exif_formated = Hash.new
      exif = EXIFR::JPEG.new(file)
      if exif.exif? 
        exif_formated[:file] = file
        exif_formated[:date] = exif.date_time_original.strftime("%d.%m.%Y") if exif.date_time_original
        exif_formated[:time] = exif.date_time_original.strftime("%k:%M") if exif.date_time_original
				exif_formated[:pixel_x_dimension] = exif.pixel_x_dimension
				exif_formated[:pixel_y_dimension] = exif.pixel_y_dimension
        exif_formated[:manufactor] = exif.make
        exif_formated[:model] = exif.model 
        exif_formated[:exposure_program] = EXPOSURE_PROGRAMS[exif.exposure_program] if exif.exposure_program
        exif_formated[:f_number] = exif.f_number.to_f
        exif_formated[:exposure_time] = exif.exposure_time.to_s 
        exif_formated[:exposure_bias] = exif.exposure_bias_value
        exif_formated[:iso] = exif.iso_speed_ratings
        exif_formated[:focal_lenght_35eq] = exif.focal_length_in_35mm_film
        exif_formated[:metering_mode] = METTERING_MODES[exif.metering_mode] if exif.metering_mode
        exif_formated[:autofocus] = SENSING_METHOD[exif.sensing_method] if exif.sensing_method
        exif_formated[:white_balance] = WHITE_BALANCES[exif.white_balance] if exif.white_balance
        exif_formated[:light_source] = LIGHT_SOURCES[exif.light_source] if exif.light_source
        exif_formated[:orientation] = ORIENTATION[exif.orientation.to_i-1] if exif.orientation
        exif_formated[:color_space] = COLOR_SPACE[exif.color_space] if exif.color_space
        exif_formated[:user_comment] = exif.user_comment if exif.user_comment
        return exif_formated
      else
        exif_formated = nil
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

     return options

    end #end parse
  end  # end class Options

  def initialize # Photostat 
    options = Options.parse(ARGV)
    @output_filename = File.expand_path(options.output_filename)
    @current_directory = Dir.pwd
		@verbose = options.verbose

    begin
     @working_directory = Dir.chdir(options.input_dir)
    rescue Errno::ENOENT => err
      puts "#{err.message}"
      exit 1
    end

    unless options.dir_recursive 
      images = File.join("*.{jpg,jpeg,JPG,JPEG}")
      else
      images = File.join("**", "*.{jpg,jpeg,JPG,JPEG}") 
    end
    @images_list = Dir.glob(images)
    puts "No photos in spedified directory: #{options.input_dir}" if @images_list.empty? 
  end

  def save_csv
      begin
        csv_file = CSV.open(@output_filename, "wb", :col_sep => ',' ) 
      rescue Errno::EACCES => err 
        puts "ERROR: #{err.message}" 
        exit 1
      end

      firstline = true
      @images_list.each do |file|
        puts "Reading exif from #{file}" if @verbose
        image = Exif.new
        exif = image.get_exif(file)
        csv_file << exif.keys if firstline   #header
        csv_file << exif.values
        firstline = false
      end
      csv_file.close
  end
  
  photostat = Photostat.new
  photostat.save_csv
end
