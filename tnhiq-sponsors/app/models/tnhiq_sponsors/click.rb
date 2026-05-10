# frozen_string_literal: true

module ::TnhiqSponsors
  class Click < ::ActiveRecord::Base
    self.table_name = "tnhiq_sponsor_clicks"

    belongs_to :placement, class_name: "::TnhiqSponsors::Placement"

    validates :clicked_at, presence: true
    validates :page_url, length: { maximum: 1024 }
    validates :user_agent, length: { maximum: 512 }
  end
end
