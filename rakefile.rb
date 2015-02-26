#! ruby
# coding: utf-8
$LOAD_PATH << "."

require "kakikudashi"

gen_f = "genbun.txt"
act_f = "actual.txt"
exp_f = "expect.txt"

file act_f => gen_f do
  k = Kakikudashi.new
  open(act_f, 'w:utf-8') do |f|
    f.puts open(gen_f, 'r:utf-8', &:readlines).map{|line| k.conv line.chomp}
  end
end

task :show => act_f do
  puts open(act_f, 'r:utf-8', &:read)
end

task :test => [act_f, exp_f] do
  act = open(act_f, 'r:utf-8', &:read)
  exp = open(exp_f, 'r:utf-8', &:read)
  puts((act == exp)? "OK":"NG")
end

task :default => [:show, :test]
