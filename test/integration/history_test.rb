require "test_helper"

class HistoryTest < ActionDispatch::IntegrationTest
  setup do
    @network1 = networks(:network1)
    @network2 = networks(:network2)
    @coordinator1 = coordinators(:coordinator1)
    @coordinator2 = coordinators(:coordinator2)

    CurrentNccNode.create!(
      network: @network1,
      vid: "0x1a0e000a",
      category: "server",
      abonent_number: "0000",
      server_number: "0001",
    )
    CurrentNccNode.create!(
      network: @network1,
      vid: "0x1a0e000b",
      category: "server",
      abonent_number: "0000",
      server_number: "0002",
    )
    CurrentNccNode.create!(
      network: @network2,
      vid: "0x1a0f000a",
      category: "server",
      abonent_number: "0000",
      server_number: "0001",
    )
    CurrentNccNode.create!(
      network: @network2,
      vid: "0x1a0f000b",
      category: "server",
      abonent_number: "0000",
      server_number: "0001",
    )
  end

  test "should return history out of Nodename prop" do
    ncc_node = CurrentNccNode.new(
      network: @network1,
      vid: "0x1a0e0001",
      name: "Nick",
    ); ncc_node.save!
    NccNode.create!(
      descendant: ncc_node,
      name: "Barry",
      creation_date: DateTime.new(2016, 9, 1),
    )
    NccNode.create!(
      descendant: ncc_node,
      name: "Larry",
      creation_date: DateTime.new(2016, 9, 3),
    )

    expected_history = [
      {
        "creation_date" => DateTime.new(2016, 9, 3),
        "name" => "Larry",
      },
      {
        "creation_date" => DateTime.new(2016, 9, 1),
        "name" => "Barry",
      },
    ]

    assert_equal(expected_history, ncc_node.history(:name))
  end

  test "should ignore ascendants with unchanged prop" do
    ncc_node = CurrentNccNode.new(
      network: @network1,
      vid: "0x1a0e0001",
      name: "Nick",
      server_number: "0001",
    ); ncc_node.save!
    NccNode.create!(
      descendant: ncc_node,
      server_number: "0002",
      creation_date: DateTime.new(2016, 9, 2),
    )

    expected_history = []

    assert_equal(expected_history, ncc_node.history(:name))
  end

  test "should return history out of Iplirconf prop" do
    ncc_node = CurrentNccNode.new(
      network: @network1,
      vid: "0x1a0e0001",
      name: "Nick",
    ); ncc_node.save!
    hw_node1 = CurrentHwNode.new(
      ncc_node: ncc_node,
      coordinator: @coordinator1,
    ); hw_node1.save!
    hw_node11 = HwNode.new(
      descendant: hw_node1,
      creation_date: DateTime.new(2016, 9, 1),
      version_decoded: "4",
    ); hw_node11.save!
    hw_node12 = HwNode.new(
      descendant: hw_node1,
      creation_date: DateTime.new(2016, 9, 2),
      version_decoded: "3",
    ); hw_node12.save!
    hw_node13 = HwNode.new(
      descendant: hw_node1,
      creation_date: DateTime.new(2016, 9, 3),
      version_decoded: "4",
    ); hw_node13.save!

    hw_node2 = CurrentHwNode.new(
      ncc_node: ncc_node,
      coordinator: @coordinator2,
    ); hw_node2.save!
    hw_node21 = HwNode.new(
      descendant: hw_node2,
      creation_date: DateTime.new(2016, 9, 1),
      version_decoded: "3",
    ); hw_node21.save!
    hw_node22 = HwNode.new(
      descendant: hw_node2,
      creation_date: DateTime.new(2016, 9, 2),
      version_decoded: "4",
    ); hw_node22.save!
    hw_node23 = HwNode.new(
      descendant: hw_node2,
      creation_date: DateTime.new(2016, 9, 3),
      version_decoded: "3",
    ); hw_node23.save!

    expected_history = [
      {
        "creation_date" => DateTime.new(2016, 9, 3),
        "version_decoded" => NccNode.most_likely(
          prop: :version_decoded,
          ncc_node: ncc_node,
          hw_nodes: HwNode.where(id: [hw_node13.id, hw_node23.id]) ,
        ),
      },
      {
        "creation_date" => DateTime.new(2016, 9, 2),
        "version_decoded" => NccNode.most_likely(
          prop: :version_decoded,
          ncc_node: ncc_node,
          hw_nodes: HwNode.where(id: [hw_node12.id, hw_node22.id]) ,
        ),
      },
      {
        "creation_date" => DateTime.new(2016, 9, 1),
        "version_decoded" => NccNode.most_likely(
          prop: :version_decoded,
          ncc_node: ncc_node,
          hw_nodes: HwNode.where(id: [hw_node11.id, hw_node21.id]) ,
        ),
      },
    ]

    assert_equal(expected_history, ncc_node.history(:version_decoded))
  end
end
