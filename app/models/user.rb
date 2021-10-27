class User < ApplicationRecord
  ## STATIC VALUES
  # TO ADD A NEW ROLE, INCLUDE IT ON THE LIST.
  ROLES = %W[hero]

  ## RELATIONS
  belongs_to :person

  ## ACT AS SUPERCLASS
  actable

  def full_name
    person.try(:full_name) || 'Sin Nombre Completo'
  end

  def phone
    person.try(:phone) || 'Sin Nº de contacto'
  end

  ## INSTANCE METHODS
  ROLES.each do |role_name|
    define_method "#{role_name}?".to_sym do
      role?.present? && (role?.eql? role_name)
    end
  end

  def role?
    actable_type.underscore
  end
end
