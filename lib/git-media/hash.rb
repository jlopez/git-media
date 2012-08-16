require 'digest/sha1'
require 'fileutils'
require 'tempfile'

module GitMedia
  class Hash
    attr_accessor :sha

    def initialize(file)
      @input = file
      @header = file.read(41)
      if file.eof? && @header && @header.match(/^([0-9a-f]{40})\n$/)
        @sha = $1
      end
    end

    def hashed?
      !sha.nil?
    end

    def available?
      File.exists? path if hashed?
    end

    def path
      @path ||= File.join(GitMedia.get_media_buffer, sha) if hashed?
    end

    def smudge output
      if !hashed?
        STDERR.puts 'Unknown git-media file format'
        passthrough output
      elsif !available?
        STDERR.puts "media missing, saving placeholder : #{sha}"
        passthrough output
      else # available
        STDERR.puts "recovering media : #{sha}"
        File.open(path, 'r') do |input|
          copy_file input, output
        end
      end
    end

    def clean output
      if hashed?
        STDERR.puts "Already hashed, passing through : #{sha}"
        passthrough output
      else
        hash!
        output.puts sha
      end
    end

    def hash!
      raise "Already hashed : #{sha}" if hashed?

      hashfunc = Digest::SHA1.new
      start = Time.now

      # read in buffered chunks of the data
      #  calculating the SHA and copying to a tempfile
      tempfile = Tempfile.new('media')
      data = @header
      while data
        hashfunc.update(data)
        tempfile.write(data)
        data = @input.read(4096)
      end
      tempfile.close

      # calculate and print the SHA of the data
      # this will also update path and hashed?
      self.sha = hashfunc.hexdigest

      # move the tempfile to our media buffer area
      FileUtils.mv(tempfile.path, path)

      elapsed = Time.now - start
      STDERR.puts "Saving media : #{sha} : #{elapsed}"
    end

    def passthrough output
      output.write @header
      copy_file @input, output
    end

    def copy_file i, o
      while data = i.read(4096)
        o.write data
      end
    end
  end
end
