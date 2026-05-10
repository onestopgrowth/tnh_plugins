# frozen_string_literal: true

module ::TnhiqOpportunities
  class Interest < ::ActiveRecord::Base
    self.table_name = "tnhiq_opportunity_interests"

    belongs_to :opportunity, class_name: "::TnhiqOpportunities::Opportunity"
    belongs_to :user, class_name: "::User"

    validates :user_id, uniqueness: { scope: :opportunity_id }
    validates :notes, length: { maximum: 2000 }
  end
end
