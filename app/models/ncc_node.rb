class NccNode < AbstractModel
  belongs_to :network
  validates :network, presence: true
  has_many :hw_nodes, dependent: :destroy
  has_many :tickets, dependent: :nullify

  def self.vid_regexp
    /\A0x[0-9a-f]{8}\z/
  end

  validates :vid,
            presence: true,
            format: { with: NccNode.vid_regexp, message: "vid should be like \"#{NccNode.vid_regexp}\"" }

  def self.where_vid_like(vid)
    search_resuls = CurrentNccNode.none
    normal_vids = VipnetParser::id(string: vid, threshold: Settings.vid_search_threshold)
    normal_vids.each do |normal_vid|
      search_resuls = search_resuls | CurrentNccNode.where("vid = ?", normal_vid)
    end
    search_resuls = search_resuls | CurrentNccNode.where("vid ILIKE ?", "%#{vid}%")
    search_resuls
  end

  def self.where_name_like(name)
    name_regexp = name.gsub(" ", ".*")
    search_resuls = CurrentNccNode.where("name ~* ?", name_regexp)
    search_resuls
  end

  def self.where_ip_like(ip)
    search_resuls = CurrentNccNode.none
    if IPv4::ip?(ip)
      search_resuls = CurrentNccNode
        .joins(hw_nodes: :node_ips)
        .where("node_ips.u32 = ?", IPv4::u32(ip))
    end
    if IPv4::cidr(ip) || IPv4::range(ip)
      lower_bound, higher_bound = IPv4::u32_bounds(ip)
      search_resuls = CurrentNccNode
        .joins(hw_nodes: :node_ips)
        .where("node_ips.u32 >= ? AND node_ips.u32 <= ?", lower_bound, higher_bound)
    end
    search_resuls
  end

  def self.where_version_decoded_like(version_decoded)
    search_resuls = CurrentNccNode.none
    version_decoded_escaped = version_decoded.gsub("_", "\\\\_").gsub("%", "\\\\%")
    search_resuls = CurrentNccNode
      .joins(:hw_nodes)
      .where("hw_nodes.version_decoded LIKE ?", "%#{version_decoded_escaped}%")
    search_resuls
  end

  def self.where_creation_date_like(creation_date)
    self.where_date_like("creation_date", creation_date)
  end

  def self.where_deletion_date_like(deletion_date)
    self.where_date_like("deletion_date", deletion_date)
  end

  def self.where_date_like(field, date)
    return unless field == "deletion_date" || field == "creation_date"
    date_escaped = date.to_s.gsub("_", "\\\\_").gsub("%", "\\\\%")
    search_resuls = CurrentNccNode.where("#{field}::text LIKE ?", "%#{date_escaped}%")
    search_resuls
  end

  def self.where_ticket_like(ticket_id)
    search_resuls = CurrentNccNode
      .joins(:tickets)
      .where("tickets.ticket_id LIKE ?", "%#{ticket_id}%")
    search_resuls
  end

  def availability
    availability = false
    response = {}
    accessips = self.accessips
    if accessips.empty?
      response[:errors] = [{
        title: "internal",
        detail: "no-accessips",
      }]
      return response
    else
      if Rails.env.test?
        availability = true
      else
        accessips.each do |accessip|
          http_request = Settings.checker.gsub("{ip}", accessip).gsub("{token}", ENV["CHECKER_TOKEN"])
          http_response = HTTParty.get(http_request)
          availability ||= http_response.parsed_response["data"]["availability"] if http_response.code == :ok
          break if availability
        end
      end
    end
    response[:data] = { "availability" => availability }
    response
  end

  def accessips
    accessips = []
    HwNode.where(ncc_node: self).each do |hw_node|
      accessip = hw_node.accessip
      accessips.push accessip if accessip
    end
    accessips
  end

  def self.to_json_ncc
    result = []
    self.all.each do |e|
      result.push(eval(e.to_json_ncc))
    end
    result.to_json.gsub("null", "nil")
  end

  def to_json_ncc
    self.to_json(
      :only => NccNode.props_from_nodename + [:vid, :creation_date_accuracy]
    ).gsub("null", "nil")
  end

  def self.props_from_nodename
    [
      :name,
      :enabled,
      :category,
      :abonent_number,
      :server_number,
    ]
  end
end
