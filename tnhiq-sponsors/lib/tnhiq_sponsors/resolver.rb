# frozen_string_literal: true

module ::TnhiqSponsors
  # Picks the best placement for a (slot, user, category_id) context.
  #
  # Specificity ranking — more-specific placements win:
  #   1. category match  (vs. no category constraint)
  #   2. niche match     (vs. no niche constraint)
  #   3. group match     (vs. no group constraint)
  #
  # Within a tier, newer placements win.
  module Resolver
    module_function

    def resolve(slot:, user:, category_id: nil)
      candidates = ::TnhiqSponsors::Placement.active_now.where(slot: slot)

      candidates = candidates.where(
        "category_id IS NULL OR category_id = ?",
        category_id,
      )

      niche = user_niche(user)
      group_ids = user.present? ? user.groups.pluck(:id) : []

      candidates = candidates.where(
        "target_niche IS NULL OR target_niche = ?",
        niche,
      )

      candidates = candidates.where(
        "target_group_id IS NULL OR target_group_id IN (?)",
        group_ids.presence || [-1],
      )

      candidates
        .to_a
        .max_by { |p| [specificity(p, category_id), p.created_at] }
    end

    def specificity(placement, category_id)
      score = 0
      score += 4 if placement.category_id.present? && placement.category_id == category_id
      score += 2 if placement.target_niche.present?
      score += 1 if placement.target_group_id.present?
      score
    end

    def user_niche(user)
      return nil unless user
      return nil unless defined?(::TnhiqNicheOnboarding::Profile)

      ::TnhiqNicheOnboarding::Profile.where(user_id: user.id).pick(:niche)
    end
  end
end
