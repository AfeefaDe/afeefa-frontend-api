class Orga < ApplicationRecord

  include Entry

  has_many :acor_relations, -> { where(type: :has_project) },
    class_name: DataModules::Actor::ActorRelation, foreign_key: 'associated_actor_id'
  has_many :project_initiators, through: :acor_relations, source: :associating_actor


  scope :active, -> { where(state: 'active') }
  scope :for_json, -> { active }

  after_initialize do |entry|
    entry.type = 0
    entry.entry_type = 'Orga'
  end

  # VALIDATIONS
  validates_uniqueness_of :title

  @c = self.default_includes
  def self.default_includes
    @c + %i(project_initiators)
  end

  def as_json(*args)
    json = super

    json[:parentOrgaId] = project_initiators.present? ? project_initiators.first.id : nil

    json
  end

end
