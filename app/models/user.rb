class User < ApplicationRecord
  include Petergate
  ############################################################################################
  ## PeterGate Roles                                                                        ##
  ## The :user role is added by default and shouldn't be included in this list.             ##
  ## The :root_admin can access any page regardless of access settings. Use with caution!   ##
  ## The multiple option can be set to true if you need users to have multiple roles.       ##
petergate roles: [:admin, :seller, :customer], multiple: false
  ############################################################################################ 

  has_many :products, dependent: :destroy
  after_initialize :set_default_role, if: :new_record?
  private

  def set_default_role
    self.role ||= 'customer'  # must be a string, not symbol
  end

  # Devise
  devise :database_authenticatable,
         :registerable,
         :jwt_authenticatable,
         jwt_revocation_strategy: Devise::JWT::RevocationStrategies::Null

  def roles=(_)
    raise "⛔️ Tried to assign to `roles`, but it doesn't exist!"
  end
end
