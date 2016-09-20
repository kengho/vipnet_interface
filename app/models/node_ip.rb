class NodeIp < ActiveRecord::Base
  belongs_to :hw_node
  validates_uniqueness_of :u32, scope: [:hw_node_id, :type]
  validates :hw_node, presence: true
  validates_each :u32 do |record, attr, value|
    unless value.to_i >= 0x0 && value.to_i <= 0xffffffff
      record.errors.add(attr, "u32 should be between 0 and 4294967295")
    end
  end

  def to_json_nonmagic
    self.to_json(:except => [:id, :created_at, :updated_at]).gsub("null", "nil")
  end

  def self.to_json_nonmagic
    result = []
    self.all.each do |e|
      result.push(eval(e.to_json_nonmagic))
    end
    result.to_json.gsub("null", "nil")
  end
end