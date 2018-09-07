module DataModules::Actor
  class ActorRelation < ApplicationRecord

    # disable rails single table inheritance
    self.inheritance_column = :_type_disabled

    # ASSOCIATIONS
    belongs_to :associating_actor, class_name: Orga # TODO: change to DataModules::Actor::Actor
    belongs_to :associated_actor, class_name: Orga # TODO: change to DataModules::Actor::Actor
  end
end
