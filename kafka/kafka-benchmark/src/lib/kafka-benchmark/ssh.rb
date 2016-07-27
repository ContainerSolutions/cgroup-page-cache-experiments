$private_key = Tempfile.new
$private_key.write File.read(ENV["SSH_PRIVATE_KEY_FILE"])
$private_key.flush
system("chmod 0600 #{$private_key.path}")

def ssh(host, command)
  system(*ssh_command(host,command))
end

def ssh_command(host, command) 
  # SSH with (forced) pseudo tty so that killing processes here will result in termination of the
  # commands we run on the other hosts.
  ["ssh", "-t", "-t", "-i", $private_key.path, host, command]
end

class SSHCaptureResult < Struct.new(:status, :stdout, :stderr)
  def ok?
    self.status.exitstatus == 0
  end

  def ok_stdout!
    raise("NOT OK! #{self}") unless self.ok? 
    self.stdout
  end
end

def ssh_capture(host, command)
  stdout, stderr, status = Open3.capture3(*ssh_command(host,command))
  SSHCaptureResult.new(status, stdout, stderr)
end

def ssh_popen(host, command)
  IO.popen(ssh_command(host,command))
end
