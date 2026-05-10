# frozen_string_literal: true

module ::TnhiqSponsors
  class Placement < ::ActiveRecord::Base
    self.table_name = "tnhiq_sponsor_placements"

    SLOTS = %w[
      category_sidebar
      opportunity_board_header
      resource_vault_section
      between_posts
      member_profile_card
      onboarding_resource
    ].freeze

    has_many :clicks,
             class_name: "::TnhiqSponsors::Click",
             foreign_key: :placement_id,
             dependent: :destroy

    validates :slot, presence: true, inclusion: { in: SLOTS }
    validates :sponsor_name, presence: true, length: { maximum: 200 }
    validates :sponsor_link, presence: true, length: { maximum: 2048 }
    validates :cta_text, length: { maximum: 100 }
    validate  :date_range_valid

    scope :active_now, -> {
      now = Time.current
      where(active: true)
        .where("starts_at IS NULL OR starts_at <= ?", now)
        .where("ends_at IS NULL OR ends_at >= ?", now)
    }

    def click_count
      clicks.count
    end

    private

    def date_range_valid
      return if starts_at.blank? || ends_at.blank?
      errors.add(:ends_at, "must be after starts_at") if ends_at <= starts_at
    end
  end
end
