class LicenceLink
  include Mongoid::Document

  belongs_to :sector
  belongs_to :activity
  belongs_to :licence

  validates :sector_id, presence: true
  validates :activity_id, presence: true
  validates :licence_id, presence: true

  index(
    { sector_id: 1, activity_id: 1, licence_id: 1 },
    unique: true,
  )

  def self.find_by_sectors_and_activities(sectors, activities)
    where(
      :sector_id.in => sectors.map(&:id),
      :activity_id.in => activities.map(&:id),
    )
  end
end
