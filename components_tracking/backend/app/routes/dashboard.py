from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.database import get_db
from app.models import Asset, Employee, Drone, Location, Project, AssetMovement
from app.schemas import DashboardStats

router = APIRouter(tags=["Dashboard"])


@router.get("/dashboard", response_model=DashboardStats)
def get_dashboard(db: Session = Depends(get_db)):
    total = db.query(func.count(Asset.id)).scalar() or 0
    available = db.query(func.count(Asset.id)).filter(Asset.status == "available").scalar() or 0
    assigned = db.query(func.count(Asset.id)).filter(Asset.status == "assigned").scalar() or 0
    in_drone = db.query(func.count(Asset.id)).filter(Asset.status == "in_drone").scalar() or 0
    testing = db.query(func.count(Asset.id)).filter(Asset.status == "testing").scalar() or 0
    maintenance = db.query(func.count(Asset.id)).filter(Asset.status == "maintenance").scalar() or 0
    missing = db.query(func.count(Asset.id)).filter(Asset.status == "missing").scalar() or 0
    damaged = db.query(func.count(Asset.id)).filter(Asset.status == "damaged").scalar() or 0

    return DashboardStats(
        total_assets=total,
        available=available,
        assigned=assigned,
        in_drone=in_drone,
        testing=testing,
        maintenance=maintenance,
        missing=missing,
        damaged=damaged
    )


@router.get("/dashboard/recent-movements")
def get_recent_movements(limit: int = 20, db: Session = Depends(get_db)):
    movements = db.query(AssetMovement).order_by(AssetMovement.created_at.desc()).limit(limit).all()
    return [
        {
            "id": m.id,
            "asset_id": m.asset_id,
            "action": m.action,
            "purpose": m.purpose,
            "remarks": m.remarks,
            "created_at": m.created_at.isoformat() if m.created_at else None,
        }
        for m in movements
    ]
