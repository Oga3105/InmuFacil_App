from sqlalchemy import Column, Integer, ForeignKey, DateTime, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .base import Base

class PropertyFavorite(Base):
    """
    Model to store user's favorite properties.
    Ensures a user can favorite a property only once.
    """
    __tablename__ = "property_favorites"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    property_id = Column(Integer, ForeignKey("properties.id", ondelete="CASCADE"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Ensure uniqueness: One user can favorite one property only once
    __table_args__ = (UniqueConstraint('user_id', 'property_id', name='_user_property_favorite_uc'),)

    # Relationships
    user = relationship("User", backref="favorites")
    property = relationship("Property", backref="favorited_by")

    def __repr__(self):
        return f"<PropertyFavorite(user_id={self.user_id}, property_id={self.property_id})>"
