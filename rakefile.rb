#! ruby
# coding: utf-8
$LOAD_PATH << "."

require "rake/clean"
require "kakikudashi"

gen_f = "genbun.txt"
act_f = "actual.txt"
exp_f = "expect.txt"

CLEAN << act_f

file act_f => gen_f do
  k = Kakikudashi.new
  open(act_f, 'w:utf-8') do |f|
    f.puts open(gen_f, 'r:utf-8', &:readlines).map{|line| k.conv line.chomp}
  end
end

task :show => act_f do
  puts open(act_f, 'r:utf-8', &:read)
end

def lines file
  open(file, 'r:utf-8', &:readlines).map(&:chomp)
end

task :test => [act_f, exp_f] do
  act = lines act_f
  exp = lines exp_f
  act.zip(exp).each do |a, e|
    if a != e
      puts "act: #{a}"
      puts "exp: #{e}"
    end
  end
end

task :default => [:test]
