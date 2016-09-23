require "test_helper"

class HwNodesTest < ActiveSupport::TestCase
  setup do
    @ncc_node = CurrentNccNode.new(network: networks(:network1), vid: "0x1a0e0001"); @ncc_node.save!
    @coordinator = coordinators(:coordinator1)
  end

  test "shouldn't save CurrentHwNode without ncc_node" do
    current_hw_node = CurrentHwNode.new(coordinator: @coordinator)
    assert_not current_hw_node.save
  end

  test "shouldn't save CurrentHwNode without coordinator" do
    current_hw_node = CurrentHwNode.new(ncc_node: @ncc_node)
    assert_not current_hw_node.save
  end

  test "shouldn't save HwNode without descendant" do
    hw_node = HwNode.new(coordinator: @coordinator, ncc_node: @ncc_node)
    assert_not hw_node.save
  end

  test "when ncc_node destroys, all its hw_nodes destroys" do
    CurrentHwNode.create!(coordinator: @coordinator, ncc_node: @ncc_node)
    assert_equal(1, CurrentHwNode.all.size)
    @ncc_node.destroy
    assert_equal(0, CurrentHwNode.all.size)
  end

  test "when coordinator destroys, all its hw_nodes destroys" do
    CurrentHwNode.create!(coordinator: @coordinator, ncc_node: @ncc_node)
    assert_equal(1, CurrentHwNode.all.size)
    @coordinator.destroy
    assert_equal(0, CurrentHwNode.all.size)
  end
end
