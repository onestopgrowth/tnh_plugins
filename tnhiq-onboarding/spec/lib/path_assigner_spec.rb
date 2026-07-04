# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::TnhiqOnboarding::PathAssigner do
  def route(stage: "stage_owner_operator", interests: ["interest_box_truck_final_mile"], pain_point: "pain_understand_numbers", help_wanted: ["help_peer_support"])
    described_class.call(stage: stage, interests: interests, pain_point: pain_point, help_wanted: help_wanted)
  end

  it "routes exploring / not-sure / choose-business / choose-lane to Beginner Explorer" do
    expect(route(stage: "stage_exploring")).to eq("beginner_explorer")
    expect(route(stage: "stage_not_sure")).to eq("beginner_explorer")
    expect(route(pain_point: "pain_choose_business")).to eq("beginner_explorer")
    expect(route(help_wanted: ["help_choose_lane"])).to eq("beginner_explorer")
  end

  it "routes driver-to-owner and owner-operator to Driver / Owner-Operator" do
    expect(route(stage: "stage_driver_to_owner")).to eq("driver_owner_operator")
    expect(route(stage: "stage_owner_operator")).to eq("driver_owner_operator")
  end

  it "routes small-fleet signals to Small Fleet Builder" do
    expect(route(stage: "stage_small_fleet")).to eq("small_fleet_builder")
    expect(route(pain_point: "pain_hiring_team")).to eq("small_fleet_builder")
    expect(route(pain_point: "pain_scaling")).to eq("small_fleet_builder")
    expect(route(interests: ["interest_small_fleet"])).to eq("small_fleet_builder")
  end

  it "routes dispatch / brokerage / compliance to Non-Asset Builder" do
    expect(route(stage: "stage_dispatch_broker_backoffice")).to eq("non_asset_builder")
    expect(route(interests: ["interest_freight_brokerage"])).to eq("non_asset_builder")
    expect(route(interests: ["interest_dispatching"])).to eq("non_asset_builder")
    expect(route(interests: ["interest_compliance_backoffice_safety"])).to eq("non_asset_builder")
  end

  it "routes specialized interests to Specialized / Contract Builder" do
    %w[
      interest_dump_truck_construction interest_hot_shot interest_government_contracting
      interest_ports_drayage_intermodal interest_towing interest_truck_parking_yards
      interest_route_business
    ].each do |i|
      expect(route(stage: "stage_existing_business_expansion", interests: [i])).to eq("specialized_contract_builder")
    end
  end

  it "routes vendor stage to Vendor / Partner" do
    expect(route(stage: "stage_vendor")).to eq("vendor_partner")
  end

  it "lets vendor and small-fleet override the beginner exception" do
    expect(route(stage: "stage_vendor", help_wanted: ["help_choose_lane"])).to eq("vendor_partner")
    expect(route(stage: "stage_exploring", interests: ["interest_small_fleet"])).to eq("small_fleet_builder")
  end

  it "applies the beginner exception over non-asset/specialized when no vendor/small-fleet" do
    expect(
      route(stage: "stage_existing_business_expansion", interests: ["interest_freight_brokerage"], help_wanted: ["help_choose_lane"]),
    ).to eq("beginner_explorer")
  end

  it "gives vendor priority over a co-occurring small-fleet interest" do
    expect(route(stage: "stage_vendor", interests: ["interest_small_fleet"])).to eq("vendor_partner")
  end
end
