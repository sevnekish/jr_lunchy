# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string
#  last_sign_in_ip        :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  name                   :string
#  admin                  :boolean          default(FALSE)
#  provider               :string
#  uid                    :string
#  organization_id        :integer
#  auth_token             :string           default("")
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_name                  (name) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#

require 'rails_helper'

RSpec.describe User, type: :model do
  context 'callbacks' do
    it { is_expected.to callback(:become_an_admin!).before(:create) }
  end

  context 'associations' do
    it { should have_many(:orders).dependent(:destroy) }
    it { should belong_to(:organization) }
    # it { should validate_uniqueness_of(:auth_token)}
  end

  context 'validations' do
    it { should validate_presence_of :name }
    it { should validate_length_of(:name).is_at_least(1).is_at_most(150) }

    it { should validate_presence_of :organization }

    it { should validate_presence_of :email }
  end

  context '#first_entry?' do
    before do
      @user = FactoryGirl.create(:user, sign_in_count: 1)
    end

    it "first sign_in" do
      expect(@user.first_entry?).to be true
    end

    it "second sign_in" do
      @user.update(sign_in_count: 2)
      expect(@user.first_entry?).to be false
    end
  end

  context '.from_omniauth' do
    before do
      FactoryGirl.create_list(:user, 5)
      @organization = FactoryGirl.create(:organization)
      @auth_info = double( 'info',
        name:  Faker::Name.name,
        email: Faker::Internet.email
      )
      @auth = double('auth', 
         provider: 'facebook',
         uid:      '889224464486842',
         info: @auth_info
      )
    end

    context 'when user does not exist' do

      context 'creates a new user' do
        it {
          expect {
            User.from_omniauth(@auth, @organization)
          }.to change(User, :count).by(1)
        }

        context 'with given data' do
          before do
            @new_user = User.from_omniauth(@auth, @organization)
          end

          it { expect(@new_user.provider).to eq(@auth.provider) }
          it { expect(@new_user.uid).to      eq(@auth.uid) }
          it { expect(@new_user.name).to     eq(@auth.info.name) }
          it { expect(@new_user.email).to    eq(@auth.info.email) }
        end
      end

    end

    context 'when user already exist' do
      context 'with given provider and uid' do
        before do
          @new_user = FactoryGirl.create(:user, provider: @auth.provider, uid: @auth.uid, organization: @organization)
        end
        it {
          expect {
            User.from_omniauth(@auth, @organization)
          }.to change(User, :count).by(0)
        }
        it { expect(User.from_omniauth(@auth, @organization)).to eq(@new_user) }
      end

      context 'with given email' do
        before do
          @new_user = FactoryGirl.create(:user, email: @auth.info.email, organization: @organization)
        end
        it {
          expect {
            User.from_omniauth(@auth, @organization)
          }.to change(User, :count).by(0)
        }
        it { expect(User.from_omniauth(@auth, @organization)).to eq(@new_user) }
      end
    end
  end

  context '#become_an_admin!' do
    before do
      @user = FactoryGirl.build(:user)
    end

    context 'when current user is first' do
      it { expect{ @user.send(:become_an_admin!) }.to change{@user.admin}.from(false).to(true) }
    end

    context 'when current user isn\'t first' do
      before do
        FactoryGirl.create(:user)
      end
      it { expect{ @user.send(:become_an_admin!) }.not_to change{@user.admin} }
    end

  end

  context "#generate_authentication_token!" do
    before do
      @user = FactoryGirl.build(:user)
    end
    
    it "generates a unique token" do
      Devise.stub(:friendly_token).and_return("auniquetoken123")
      @user.generate_authentication_token!
      expect(@user.auth_token).to eql "auniquetoken123"
    end

    it "generates another token when one already has been taken" do
      existing_user = FactoryGirl.create(:user, auth_token: "auniquetoken123")
      @user.generate_authentication_token!
      expect(@user.auth_token).not_to eql existing_user.auth_token
    end
  end
end
