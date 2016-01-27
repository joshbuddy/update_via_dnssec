#!/usr/bin/env ruby

require 'base64'

class Generator
  attr_reader :origins, :branches

  def initialize
    @origins = []
    @branches = {}
  end

  def parse(args)
    args.each do |arg|
      case arg
      when /^([a-zA-Z0-9_-]*?):([0-9a-f]{40})$/
        branch_name = $1
        sha = $2
        add_branch(branch_name, sha)
      else
        add_origin(arg)
      end
    end
  end

  def add_branch(name, sha)
    @branches[name] = sha
  end

  def add_origin(origin)
    @origins << origin
  end

  def to_records(base)
    throw "origins is empty" if @origins.empty?
    throw "branches is empty" if @branches.empty?

    remaining_origins = @origins.dup
    remaining_branches = @branches.to_a.dup
    records = []

    until remaining_origins.empty? && remaining_branches.empty?
      throw "too many records" if records.size == 10

      removed_origins = []
      removed_branches = []

      # while too big!
      while (candidate_record = generate_record(remaining_origins, remaining_branches, !(removed_origins.empty? && removed_branches.empty?))).size > 255
        removed_branches << remaining_branches.pop and next if remaining_branches.size == 0
        removed_origins << remaining_origins.pop and next if remaining_origins.size == 0

        throw "unable to generate a small enough record"
      end

      records << candidate_record

      remaining_branches = removed_branches
      remaining_origins =removed_origins
    end

    full_records = []
    records.each_with_index do |record, index|
      full_records << "_gitdnssec#{index}.#{base} 600 IN TXT \"#{record}\""
    end
    full_records
  end

  def generate_record(remaining_origins, remaining_branches, continuing)
    formatted_branches = remaining_branches.map do |(name, sha)|
      base64_sha = [[sha].pack("H*")].pack("m0")
      "#{name}:#{base64_sha}"
    end

    "v=uvd1 #{continuing ? 'c ': ''}o=#{remaining_origins.join(',')} b=#{formatted_branches.join(',')}"
  end
end

if __FILE__ == $0
  generator = Generator.new
  args = ARGV.dup
  domain = args.shift
  generator.parse(args)
  puts "To publish origins #{generator.origins.join(', ')} with branches #{generator.branches.to_a.join(', ')} add the following DNS records:"
  records = generator.to_records(domain)
  puts
  puts records.map {|r| "    #{r}"}.join("\n")
end

