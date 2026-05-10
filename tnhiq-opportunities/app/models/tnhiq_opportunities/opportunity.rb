# frozen_string_literal: true

module ::TnhiqOpportunities
  class Opportunity < ::ActiveRecord::Base
    self.table_name = "tnhiq_opportunities"

    SOURCE_TYPES = %w[direct_shipper broker_partner internal].freeze
    STATUSES     = %w[active expired archived draft].freeze
    TIERS        = %w[free core premium founder].freeze

    EQUIPMENT_TYPES = %w[
      dry_van reefer flatbed step_deck rgn box_truck cargo_van sprinter hotshot_trailer other
    ].freeze

    has_many :interests,
             class_name: "::TnhiqOpportunities::Interest",
             foreign_key: :opportunity_id,
             dependent: :destroy
    belongs_to :posted_by_user, class_name: "::User", optional: true

    validates :title, presence: true, length: { maximum: 200 }
    validates :source_type, inclusion: { in: SOURCE_TYPES }
    validates :status, inclusion: { in: STATUSES }
    validates :tier_required, inclusion: { in: TIERS }
    validates :equipment_type, inclusion: { in: EQUIPMENT_TYPES, allow_nil: true }
    validates :external_reference_id, uniqueness: { allow_nil: true }

    scope :active,   -> { where(status: "active") }
    scope :listable, -> { active.where("expires_at IS NULL OR expires_at > ?", Time.current) }
    scope :expired_now, -> { where(status: "active").where("expires_at IS NOT NULL AND expires_at <= ?", Time.current) }

    def expired?
      expires_at.present? && expires_at <= Time.current
    end

    def interest_count
      interests.count
    end
  end
end
