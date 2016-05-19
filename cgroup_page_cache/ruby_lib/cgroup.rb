require 'fileutils'
require 'pathname'

def clear_all_caches
  puts "############################"
  3.times do
    system("free -m")
    system("sync; echo 3 > /proc/sys/vm/drop_caches")
  end
  puts "############################"
end

class CGroup
  BASE = Pathname.new("/sys/fs/cgroup/memory")
  attr_reader :path

  def initialize(name, parent = nil)
    @name = name
    @parent = parent
    if parent.nil?
      @path = Pathname.new(@name)
    else
      @path = @parent.path.join(@name)
    end
  end

  def fs_path
    BASE.join(@path)
  end

  def create!
    FileUtils.mkdir(fs_path).to_s
    self
  end

  def destroy!
    FileUtils.rmdir(fs_path)
    nil
  end

  def set(name, val)
    File.write(fs_path.join("memory.limit_in_bytes").to_s, val)
    nil
  end

  def get(name)
    File.read(fs_path.join("memory.limit_in_bytes").to_s).chomp
  end

  def child(name)
    CGroup.new(name, self)
  end

  def system(cmd)
    puts("cgexec -g memory:#{@path.to_s} #{cmd}")
    Kernel.system("cgexec -g memory:#{@path.to_s} #{cmd}")
  end

  def stats
    Hash[File.readlines(fs_path.join("memory.stat")).map { |line| line.split(" ") }]
  end

  def major_pagefaults
    self.stats["pgmajfault"]
  end
end
