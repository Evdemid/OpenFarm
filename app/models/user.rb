class User
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :guides
  has_many :gardens

  has_and_belongs_to_many :favorited_guides, class_name: 'Guide', inverse_of: nil

  has_one :token, dependent: :delete
  has_one :user_setting
  ## Database authenticatable
  field :email,              :type => String, :default => ""
  field :encrypted_password, :type => String, :default => ""

  ## Recoverable
  field :reset_password_token,   :type => String
  field :reset_password_sent_at, :type => Time

  ## Rememberable
  field :remember_created_at, :type => Time

  ## Trackable
  field :sign_in_count,      :type => Integer, :default => 0
  field :current_sign_in_at, :type => Time
  field :last_sign_in_at,    :type => Time
  field :current_sign_in_ip, :type => String
  field :last_sign_in_ip,    :type => String

  field :display_name, type: String
  validates_presence_of :display_name
  NO_TOS = 'to the Terms of Service and Privacy Policy'
  field :agree, type: Boolean
  validates :agree, acceptance: { accept: true, message: NO_TOS }, on: :create

  field :mailing_list, type: Mongoid::Boolean, default: false
  field :help_list, type: Mongoid::Boolean, default: false

  field :admin, type: Mongoid::Boolean, default: false

  # Privacy fields
  field :is_private, type: Mongoid::Boolean, default: false
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable
  # These are needed to be defined. Dunno why this doesn't
  # get automatically generated. Part of Devise.Confirmable
  # http://stackoverflow.com/a/9952241/154392
  field :confirmation_token,   :type => String
  field :confirmed_at,         :type => Time
  field :confirmation_sent_at, :type => Time
  field :unconfirmed_email,    :type => String

  has_merit

  after_save :create_garden_if_none

  def user_setting
    UserSetting.find_or_create_by(user: self)
  end

  def has_filled_required_settings?
    user_setting.location.present? && user_setting.units.present?
  end

  def favorite_crop_image_from_user_setting
    user_setting.favorite_crop_image
  end

  protected

  def confirmation_required?
    false
  end

  private

  def create_garden_if_none
    if self.gardens.all.count == 0 && self.confirmed?
      Gardens::CreateGarden.run(
        user: self,
        attributes: { is_private: true,
                      name: I18n::t('registrations.your_first_garden') }
      )
    end
  end
end
