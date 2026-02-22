from pydantic import BaseModel, EmailStr
from datetime import datetime

class LeadCreate(BaseModel):
    email: EmailStr

class LeadResponse(BaseModel):
    id: int
    email: str
    created_at: datetime

    class Config:
        from_attributes = True
