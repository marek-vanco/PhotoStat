#!/usr/bin/env ruby

require 'rubygems'
require 'exifr'
require 'optparse'
require 'ostruct'
require 'pp'


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
            @exifdata[:model] = exif.mode 
            @exifdata[:exposure_program] = EXPOSURE_PROGRAMS[exif.exposure_program] unless exif.mode = nil
            @exifdata[:exposure_time] = exif.exposure_time.to_s unless exif.mode = nil
            @exifdata[:f_number] = exif.f_number.to_f
            @exifdata[:exposure_bias] = exif.exposure_bias_value
            @exifdata[:iso] = exif.iso_speed_ratings
            @exifdata[:focal_lenght_35eq] = exif.focal_length_in_35mm_film
            @exifdata[:mettering_mode] = METTERING_MODES[exif.metering_mode]
            @exifdata[:white_balance] = WHITE_BALANCES[exif.white_balance]
            @exifdata[:light_source] = LIGHT_SOURCES[exif.light_source]
            @exifdata[:date] = exif.date_time_original.strftime("%d.%m.%Y")
            @exifdata[:time] = exif.date_time_original.strftime("%k:%M")
            @exifdata[:comment] = exif.comment
        else
          exifdata = nil
        end #if
    end
  end      # end class Exif 

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
          puts "This scrit is under GNU software licence."
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
    @output_filename = options.output_filename

    @current_directory = Dir.pwd
    @working_directory = Dir.chdir(options.input_dir)

    unless options.dir_recursive 
      images = File.join("*.{jpg,jpeg,JPG}")
      else
      images = File.join("**", "*.{jpg,jpeg,JPG}") 
    end
    @images_list = Dir.glob(images)
  end

  def save_values
#    if File.exist?(@current_directory+"/"+@output_filename)
#      puts "File exist. Do you want delete old file (Y/n)?"
#      yn = gets
#    else
      of = File.new(@current_directory+"/"+@output_filename, "a+")
      datalinehead = "#{FIELDSEP}FILENAME#{FIELDSEP}#{DELIMITER}#{FIELDSEP}DATE#{FIELDSEP}#{DELIMITER}#{FIELDSEP}TIME#{FIELDSEP}#{DELIMITER}#{FIELDSEP}MODEL#{FIELDSEP}#{DELIMITER}#{FIELDSEP}PROGRAM#{FIELDSEP}#{DELIMITER}#{FIELDSEP}EXPOSURE_TIME#{FIELDSEP}#{DELIMITER}#{FIELDSEP}APERTURE#{FIELDSEP}#{DELIMITER}#{FIELDSEP}ISO#{FIELDSEP}#{DELIMITER}#{FIELDSEP}EXPOSURE_COMPENSATION#{FIELDSEP}#{DELIMITER}#{FIELDSEP}METTERING_MODE#{FIELDSEP}#{DELIMITER}#{FIELDSEP}FOCAL_DISTANCE_35MM#{FIELDSEP}#{DELIMITER}#{FIELDSEP}WHITE_BALANCE#{FIELDSEP}#{DELIMITER}#{FIELDSEP}WB_LIGHT_SOURCE#{FIELDSEP}\x0A"
      of.write(datalinehead)
      images_list.each do |file|
        puts "reading Exif from #{file}" if @options.verbose
        image = Exif.new(file)
        image.get_exif(file)
        dataline = "#{FIELDSEP}#{file}#{FIELDSEP}#{DELIMITER}#{FIELDSEP}#{image.exifdata[:date]}#{FIELDSEP}#{DELIMITER}#{FIELDSEP}#{image.exifdata[:time]}#{FIELDSEP}#{DELIMITER}#{FIELDSEP}#{image.exifdata[:model]}#{FIELDSEP}#{DELIMITER}#{FIELDSEP}#{image.exifdata[:exposure_program]}#{FIELDSEP}#{DELIMITER}#{FIELDSEP}#{image.exifdata[:exposure_time]}#{FIELDSEP}#{DELIMITER}#{FIELDSEP}#{image.exifdata[:f_number]}#{FIELDSEP}#{DELIMITER}#{FIELDSEP}#{image.exifdata[:iso]}#{FIELDSEP}#{DELIMITER}#{FIELDSEP}#{image.exifdata[:exposure_bias]}#{FIELDSEP}#{DELIMITER}#{FIELDSEP}#{image.exifdata[:mettering_mode]}#{FIELDSEP}#{DELIMITER}#{FIELDSEP}#{image.exifdata[:focal_lenght_35eq]}#{FIELDSEP}#{DELIMITER}#{FIELDSEP}#{image.exifdata[:white_balance]}#{FIELDSEP}#{DELIMITER}#{FIELDSEP}#{image.exifdata[:light_source]}#{FIELDSEP}\x0A"
        of.write(dataline)
      end
      of.close
#    end
  end
  
  photostat = Photostat.new
  photostat.save_values
end
