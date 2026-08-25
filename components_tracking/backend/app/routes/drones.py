from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Drone
from app.schemas import DroneCreate, DroneResponse

router = APIRouter(prefix="/drones", tags=["Drones"])


@router.post("/", response_model=DroneResponse)
def create_drone(data: DroneCreate, db: Session = Depends(get_db)):
    existing = db.query(Drone).filter(Drone.drone_id == data.drone_id).first()
    if existing:
        raise HTTPException(status_code=400, detail="Drone ID already exists")
    drone = Drone(**data.model_dump())
    db.add(drone)
    db.commit()
    db.refresh(drone)
    return drone


@router.get("/", response_model=list[DroneResponse])
def list_drones(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return db.query(Drone).offset(skip).limit(limit).all()


@router.get("/{drone_id}", response_model=DroneResponse)
def get_drone(drone_id: int, db: Session = Depends(get_db)):
    drone = db.query(Drone).filter(Drone.id == drone_id).first()
    if not drone:
        raise HTTPException(status_code=404, detail="Drone not found")
    return drone


@router.put("/{drone_id}", response_model=DroneResponse)
def update_drone(drone_id: int, data: DroneCreate, db: Session = Depends(get_db)):
    drone = db.query(Drone).filter(Drone.id == drone_id).first()
    if not drone:
        raise HTTPException(status_code=404, detail="Drone not found")
    for key, value in data.model_dump().items():
        setattr(drone, key, value)
    db.commit()
    db.refresh(drone)
    return drone


@router.delete("/{drone_id}")
def delete_drone(drone_id: int, db: Session = Depends(get_db)):
    drone = db.query(Drone).filter(Drone.id == drone_id).first()
    if not drone:
        raise HTTPException(status_code=404, detail="Drone not found")
    db.delete(drone)
    db.commit()
    return {"detail": "Drone deleted"}


@router.get("/{drone_id}/assets")
def get_drone_assets(drone_id: int, db: Session = Depends(get_db)):
    drone = db.query(Drone).filter(Drone.id == drone_id).first()
    if not drone:
        raise HTTPException(status_code=404, detail="Drone not found")
    from app.models import Asset
    assets = db.query(Asset).filter(Asset.current_drone_id == drone_id).all()
    return [
        {
            "id": a.id, "asset_id": a.asset_id, "name": a.name,
            "category": a.category, "status": a.status, "model": a.model
        }
        for a in assets
    ]
