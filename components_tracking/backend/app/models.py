from datetime import datetime

from sqlalchemy import (
    Column, Integer, String, Text, DateTime, Enum, ForeignKey
)
from sqlalchemy.orm import relationship

from app.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, autoincrement=True)
    username = Column(String(100), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    role = Column(Enum("admin", "manager", "employee", name="user_role"), default="employee")
    employee_id = Column(Integer, ForeignKey("employees.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    employee = relationship("Employee", back_populates="user")


class Employee(Base):
    __tablename__ = "employees"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(200), nullable=False)
    email = Column(String(200), unique=True, nullable=False)
    department = Column(String(100), nullable=True)
    phone = Column(String(20), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="employee", uselist=False)
    assets = relationship("Asset", back_populates="current_user")


class Location(Base):
    __tablename__ = "locations"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(200), nullable=False)
    building = Column(String(200), nullable=True)
    room = Column(String(100), nullable=True)
    description = Column(Text, nullable=True)

    assets = relationship("Asset", back_populates="current_location")


class Project(Base):
    __tablename__ = "projects"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    status = Column(Enum("active", "completed", "on_hold", name="project_status"), default="active")
    created_at = Column(DateTime, default=datetime.utcnow)

    assets = relationship("Asset", back_populates="project")


class Drone(Base):
    __tablename__ = "drones"

    id = Column(Integer, primary_key=True, autoincrement=True)
    drone_id = Column(String(50), unique=True, nullable=False)
    name = Column(String(200), nullable=False)
    model = Column(String(200), nullable=True)
    status = Column(Enum("active", "maintenance", "grounded", name="drone_status"), default="active")
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    assets = relationship("Asset", back_populates="current_drone")


class Asset(Base):
    __tablename__ = "assets"

    id = Column(Integer, primary_key=True, autoincrement=True)
    asset_id = Column(String(50), unique=True, nullable=False)
    category = Column(String(100), nullable=False)
    name = Column(String(200), nullable=False)
    serial_number = Column(String(200), nullable=True)
    model = Column(String(200), nullable=True)
    status = Column(
        Enum("available", "assigned", "in_drone", "testing", "maintenance", "missing", "damaged", name="asset_status"),
        default="available"
    )
    condition_type = Column("condition", Enum("good", "fair", "poor", name="asset_condition"), default="good")
    current_user_id = Column(Integer, ForeignKey("employees.id"), nullable=True)
    current_location_id = Column(Integer, ForeignKey("locations.id"), nullable=True)
    current_drone_id = Column(Integer, ForeignKey("drones.id"), nullable=True)
    project_id = Column(Integer, ForeignKey("projects.id"), nullable=True)
    remarks = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    current_user = relationship("Employee", back_populates="assets")
    current_location = relationship("Location", back_populates="assets")
    current_drone = relationship("Drone", back_populates="assets")
    project = relationship("Project", back_populates="assets")
    movements = relationship("AssetMovement", back_populates="asset", order_by="AssetMovement.created_at.desc()")


class AssetMovement(Base):
    __tablename__ = "asset_movements"

    id = Column(Integer, primary_key=True, autoincrement=True)
    asset_id = Column(Integer, ForeignKey("assets.id"), nullable=False)
    action = Column(
        Enum("assigned", "transferred", "returned", "installed_drone", "removed_drone",
             "reported_missing", "reported_damaged", "created", name="movement_action"),
        nullable=False
    )
    from_user_id = Column(Integer, ForeignKey("employees.id"), nullable=True)
    to_user_id = Column(Integer, ForeignKey("employees.id"), nullable=True)
    from_location_id = Column(Integer, ForeignKey("locations.id"), nullable=True)
    to_location_id = Column(Integer, ForeignKey("locations.id"), nullable=True)
    from_drone_id = Column(Integer, ForeignKey("drones.id"), nullable=True)
    to_drone_id = Column(Integer, ForeignKey("drones.id"), nullable=True)
    from_status = Column(String(50), nullable=True)
    to_status = Column(String(50), nullable=True)
    purpose = Column(Text, nullable=True)
    remarks = Column(Text, nullable=True)
    performed_by = Column(Integer, ForeignKey("employees.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    asset = relationship("Asset", back_populates="movements")
