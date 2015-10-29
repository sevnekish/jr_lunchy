class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    if user.admin?
      can :manage, :all
    else
      can :read, :all #TODO can't read all, change it
      can [:read, :update, :destroy], User do |managed_user|
        managed_user == user
      end
    end
  end

end