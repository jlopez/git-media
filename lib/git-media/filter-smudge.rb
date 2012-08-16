require 'git-media/hash'

module GitMedia
  module FilterSmudge

    def self.run!
      STDIN.binmode
      STDOUT.binmode
      sha = GitMedia::Hash.new(STDIN)
      # TODO: download media if config specifies it
      sha.smudge(STDOUT)
    end

  end
end
