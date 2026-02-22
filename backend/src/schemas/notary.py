
from pydantic import BaseModel
from typing import Optional

class NotaryBase(BaseModel):
    name: str
    address_line: str
    city: str
    email: str
    phone: str

class NotaryCreate(NotaryBase):
    pass

class NotaryResponse(NotaryBase):
    id: int
    integration_type: str

    class Config:
        from_attributes = True

class NotaryAssignmentRequest(BaseModel):
    offer_id: int
    notary_id: int
