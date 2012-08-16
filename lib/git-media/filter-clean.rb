require 'git-media/hash'

module GitMedia
  module FilterClean

    def self.run!
      STDIN.binmode
      STDOUT.binmode
      hash = GitMedia::Hash.new(STDIN)
      hash.clean(STDOUT)
    end

  end
end
