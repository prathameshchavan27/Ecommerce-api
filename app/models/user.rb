class User < ApplicationRecord
  ############################################################################################
  ## PeterGate Roles                                                                        ##
  ## The :user role is added by default and shouldn't be included in this list.             ##
  ## The :root_admin can access any page regardless of access settings. Use with caution!   ##
  ## The multiple option can be set to true if you need users to have multiple roles.       ##
  petergate(roles: [:admin, :seller, :customer], multiple: false)   

  after_initialize :set_default_role, if: :new_record?

  private

  def set_default_role
    self.role ||= :customer  # or :seller or :admin
  end                                  ##
  ############################################################################################ 
 

  devise :database_authenticatable,
         :registerable,
         :jwt_authenticatable,
         jwt_revocation_strategy: Devise::JWT::RevocationStrategies::Null
end
