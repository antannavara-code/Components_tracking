from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr


class UserCreate(BaseModel):
    username: str
    password: str
    role: str = "employee"
    employee_id: Optional[int] = None


class UserLogin(BaseModel):
    username: str
    password: str


class UserResponse(BaseModel):
    id: int
    username: str
    role: str
    employee_id: Optional[int] = None

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse


class EmployeeCreate(BaseModel):
    name: str
    email: str
    department: Optional[str] = None
    phone: Optional[str] = None


class EmployeeResponse(BaseModel):
    id: int
    name: str
    email: str
    department: Optional[str] = None
    phone: Optional[str] = None

    class Config:
        from_attributes = True


class LocationCreate(BaseModel):
    name: str
    building: Optional[str] = None
    room: Optional[str] = None
    description: Optional[str] = None


class LocationResponse(BaseModel):
    id: int
    name: str
    building: Optional[str] = None
    room: Optional[str] = None
    description: Optional[str] = None

    class Config:
        from_attributes = True


class ProjectCreate(BaseModel):
    name: str
    description: Optional[str] = None
    status: str = "active"


class ProjectResponse(BaseModel):
    id: int
    name: str
    description: Optional[str] = None
    status: str

    class Config:
        from_attributes = True


class DroneCreate(BaseModel):
    drone_id: str
    name: str
    model: Optional[str] = None
    status: str = "active"
    description: Optional[str] = None


class DroneResponse(BaseModel):
    id: int
    drone_id: str
    name: str
    model: Optional[str] = None
    status: str
    description: Optional[str] = None

    class Config:
        from_attributes = True


class AssetCreate(BaseModel):
    asset_id: str
    category: str
    name: str
    serial_number: Optional[str] = None
    model: Optional[str] = None
    status: str = "available"
    condition_type: str = "good"
    current_user_id: Optional[int] = None
    current_location_id: Optional[int] = None
    current_drone_id: Optional[int] = None
    project_id: Optional[int] = None
    remarks: Optional[str] = None


class AssetUpdate(BaseModel):
    category: Optional[str] = None
    name: Optional[str] = None
    serial_number: Optional[str] = None
    model: Optional[str] = None
    status: Optional[str] = None
    condition_type: Optional[str] = None
    current_user_id: Optional[int] = None
    current_location_id: Optional[int] = None
    current_drone_id: Optional[int] = None
    project_id: Optional[int] = None
    remarks: Optional[str] = None


class AssetResponse(BaseModel):
    id: int
    asset_id: str
    category: str
    name: str
    serial_number: Optional[str] = None
    model: Optional[str] = None
    status: str
    condition_type: str
    current_user_id: Optional[int] = None
    current_location_id: Optional[int] = None
    current_drone_id: Optional[int] = None
    project_id: Optional[int] = None
    remarks: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    current_user: Optional[EmployeeResponse] = None
    current_location: Optional[LocationResponse] = None
    current_drone: Optional[DroneResponse] = None
    project: Optional[ProjectResponse] = None

    class Config:
        from_attributes = True


class AssetAssign(BaseModel):
    employee_id: int
    location_id: Optional[int] = None
    project_id: Optional[int] = None
    purpose: Optional[str] = None
    remarks: Optional[str] = None


class AssetTransfer(BaseModel):
    to_employee_id: int
    purpose: Optional[str] = None
    remarks: Optional[str] = None


class AssetReturn(BaseModel):
    location_id: Optional[int] = None
    remarks: Optional[str] = None


class AssetDroneAssign(BaseModel):
    drone_id: int
    purpose: Optional[str] = None
    remarks: Optional[str] = None


class AssetReport(BaseModel):
    description: Optional[str] = None
    remarks: Optional[str] = None


class MovementResponse(BaseModel):
    id: int
    asset_id: int
    action: str
    from_user_id: Optional[int] = None
    to_user_id: Optional[int] = None
    from_location_id: Optional[int] = None
    to_location_id: Optional[int] = None
    from_drone_id: Optional[int] = None
    to_drone_id: Optional[int] = None
    from_status: Optional[str] = None
    to_status: Optional[str] = None
    purpose: Optional[str] = None
    remarks: Optional[str] = None
    performed_by: Optional[int] = None
    created_at: datetime

    class Config:
        from_attributes = True


class DashboardStats(BaseModel):
    total_assets: int
    available: int
    assigned: int
    in_drone: int
    testing: int
    maintenance: int
    missing: int
    damaged: int
