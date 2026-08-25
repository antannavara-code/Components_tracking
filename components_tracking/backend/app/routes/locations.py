from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Location
from app.schemas import LocationCreate, LocationResponse

router = APIRouter(prefix="/locations", tags=["Locations"])


@router.post("/", response_model=LocationResponse)
def create_location(data: LocationCreate, db: Session = Depends(get_db)):
    location = Location(**data.model_dump())
    db.add(location)
    db.commit()
    db.refresh(location)
    return location


@router.get("/", response_model=list[LocationResponse])
def list_locations(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return db.query(Location).offset(skip).limit(limit).all()


@router.get("/{location_id}", response_model=LocationResponse)
def get_location(location_id: int, db: Session = Depends(get_db)):
    location = db.query(Location).filter(Location.id == location_id).first()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")
    return location


@router.put("/{location_id}", response_model=LocationResponse)
def update_location(location_id: int, data: LocationCreate, db: Session = Depends(get_db)):
    location = db.query(Location).filter(Location.id == location_id).first()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")
    for key, value in data.model_dump().items():
        setattr(location, key, value)
    db.commit()
    db.refresh(location)
    return location


@router.delete("/{location_id}")
def delete_location(location_id: int, db: Session = Depends(get_db)):
    location = db.query(Location).filter(Location.id == location_id).first()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")
    db.delete(location)
    db.commit()
    return {"detail": "Location deleted"}
