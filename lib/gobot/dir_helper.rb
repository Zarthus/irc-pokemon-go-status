class Dir
  def self.back(path, levels = 1)
    path.split(File::SEPARATOR)[0..-(levels + 1)].join(File::SEPARATOR)
  end
end
