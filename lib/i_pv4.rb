module IPv4
  def ip?(string)
    octets = string.split(".")
    return false unless octets.size == 4
    octets.each do |octet|
      return false unless octet =~ /^\d+$/
      return false unless octet.to_i.between?(0, 255)
    end

    true
  end

  def cidr(string)
    string =~ /^(.*)\/(.*)$/
    return nil unless Regexp.last_match
    return nil unless Regexp.last_match.size == 3
    probably_ip = Regexp.last_match(1)
    probably_mask = Regexp.last_match(2)
    return nil unless IPv4.ip?(probably_ip)
    return nil unless probably_mask =~ /^\d+$/
    return nil unless probably_mask.to_i.between?(0, 32)

    [probably_ip, probably_mask.to_i]
  end

  def u32(string)
    return nil unless IPv4.ip?(string)
    octets = string.split(".")

    octets.map { |octet| octet.to_i.to_s(16).rjust(2, "0") }.join.to_i(16)
  end

  def ip(u32)
    return nil unless u32.is_a?(Numeric)
    return nil unless u32.between?(0, 0xffffffff)

    # http://stackoverflow.com/a/12039844/6376451
    hex_octets = u32.to_s(16).rjust(8, "0").chars.each_slice(2).map(&:join)

    hex_octets.map { |octet| octet.to_i(16) }.join(".")
  end

  def range(string)
    string =~ /^(.*)-(.*)$/
    return nil unless Regexp.last_match
    return nil unless Regexp.last_match.size == 3
    probably_lower_bound = Regexp.last_match(1)
    return nil unless IPv4.ip?(probably_lower_bound)
    probably_higher_bound = Regexp.last_match(2)
    return nil unless IPv4.ip?(probably_higher_bound)
    unless IPv4.u32(probably_lower_bound) <= IPv4.u32(probably_higher_bound)
      return nil
    end

    [probably_lower_bound, probably_higher_bound]
  end

  def u32_bounds(string)
    cidr = IPv4.cidr(string)
    range = IPv4.range(string)
    return nil unless cidr || range

    if cidr
      bitwise_mask = 0xffffffff >> (32 - cidr.last) << (32 - cidr.last)
      network_size = 1 << (32 - cidr.last)
      lower_bound = IPv4.u32(cidr.first) & bitwise_mask
      higher_bound = lower_bound + network_size - 1
    elsif range
      lower_bound = IPv4.u32(range.first)
      higher_bound = IPv4.u32(range.last)
    end

    [lower_bound, higher_bound]
  end

  module_function :ip?, :cidr, :u32, :ip, :range, :u32_bounds
end
