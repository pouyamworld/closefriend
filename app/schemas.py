from datetime import datetime
from pydantic import BaseModel, EmailStr, Field
from typing import List, Optional

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

class UserOut(BaseModel):
    id: int
    email: EmailStr
    is_verified: bool

    class Config:
        from_attributes = True

# Email signup flow
class RegisterStartIn(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6)

class RegisterVerifyIn(BaseModel):
    email: EmailStr
    code: str = Field(min_length=4, max_length=8)

# Login
class LoginIn(BaseModel):
    email: EmailStr
    password: str

# Google sign-in
class GoogleSignInIn(BaseModel):
    id_token: str

# Telegram sign-in (Login Widget)
class TelegramSignInIn(BaseModel):
    id: int
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    username: Optional[str] = None
    photo_url: Optional[str] = None
    auth_date: int
    hash: str

# Dashboard

# ورودی جدید برای close friends
class CloseFriendItemIn(BaseModel):
    acc_id: str
    image_url: str
    is_bestie: bool

class CloseFriendsIn(BaseModel):
    friends: list[CloseFriendItemIn]

class CloseFriendEventOut(BaseModel):
    id: int
    user_id: int
    friend_ids: dict
    created_at: datetime

    class Config:
        from_attributes = True
