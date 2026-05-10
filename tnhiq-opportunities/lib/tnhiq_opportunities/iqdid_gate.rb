# frozen_string_literal: true

module ::TnhiqOpportunities
  # Stub for the IQDID verification check used by tnhiq-iqdid-identity (Step 2).
  # That plugin writes UserCustomField "iqdid_credential_type" on successful
  # verification. Until it ships, this returns false for everyone except staff.
  #
  # When tnhiq-iqdid-identity is built, replace the body of `verified?` to read
  # the actual credential field — no changes needed in the opportunities plugin.
  module IqdidGate
    CREDENTIAL_FIELD = "iqdid_credential_type"

    module_function

    def verified?(user)
      return false unless user
      return true if user.staff?

      type = user.custom_fields[CREDENTIAL_FIELD]
      type.present?
    end
  end
end
