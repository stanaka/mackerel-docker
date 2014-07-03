#! /usr/bin/env ruby
require 'docker'

now = Time.now
BASE_CPU='/sys/fs/cgroup/cpuacct/docker'
BASE_MEM='/sys/fs/cgroup/memory/docker'
period = 5

output = []
Docker::Container.all.each do |c|
  name = "#{c.info["Image"]}_#{c.info["Names"].join("_")}"
  name = name.tr(':/', '_')

  cpuacct_last = File.read("#{BASE_CPU}/#{c.id}/cpuacct.stat")
  usr_last = cpuacct_last.match(/user (\d+)/)[1].to_i
  sys_last = cpuacct_last.match(/system (\d+)/)[1].to_i
  sleep(period)
  cpuacct_now = File.read("#{BASE_CPU}/#{c.id}/cpuacct.stat")
  usr_now = cpuacct_now.match(/user (\d+)/)[1].to_i
  sys_now = cpuacct_now.match(/system (\d+)/)[1].to_i
  output.push ["docker.cpu.#{name}_user",   (usr_now - usr_last) / period]
  output.push ["docker.cpu.#{name}_system", (sys_now - sys_last) / period]

  mem = File.read("#{BASE_MEM}/#{c.id}/memory.stat")
  rss = mem.match(/rss (\d+)/)[1]
  output.push ["docker.memory.#{name}_rss", rss]
end

output.each do |o|
  puts "#{o[0]}\t#{o[1]}\t#{now.to_i}"
end
