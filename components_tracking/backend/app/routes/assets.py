from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime

from app.database import get_db
from app.models import Asset, AssetMovement, Employee
from app.schemas import (
    AssetCreate, AssetUpdate, AssetResponse,
    AssetAssign, AssetTransfer, AssetReturn,
    AssetDroneAssign, AssetReport, MovementResponse
)

router = APIRouter(prefix="/assets", tags=["Assets"])


def create_movement(db: Session, asset_id: int, action: str, **kwargs):
    movement = AssetMovement(asset_id=asset_id, action=action, **kwargs)
    db.add(movement)
    return movement


@router.post("/", response_model=AssetResponse)
def create_asset(asset: AssetCreate, db: Session = Depends(get_db)):
    existing = db.query(Asset).filter(Asset.asset_id == asset.asset_id).first()
    if existing:
        raise HTTPException(status_code=400, detail="Asset ID already exists")

    db_asset = Asset(**asset.model_dump())
    db.add(db_asset)
    db.flush()

    create_movement(db, db_asset.id, "created", to_status="available")
    db.commit()
    db.refresh(db_asset)
    return db_asset


@router.get("/", response_model=list[AssetResponse])
def list_assets(
    skip: int = 0,
    limit: int = 100,
    status: str = None,
    category: str = None,
    search: str = None,
    db: Session = Depends(get_db)
):
    query = db.query(Asset)
    if status:
        query = query.filter(Asset.status == status)
    if category:
        query = query.filter(Asset.category == category)
    if search:
        query = query.filter(
            (Asset.asset_id.ilike(f"%{search}%")) |
            (Asset.name.ilike(f"%{search}%")) |
            (Asset.serial_number.ilike(f"%{search}%"))
        )
    return query.offset(skip).limit(limit).all()


@router.get("/{asset_db_id}", response_model=AssetResponse)
def get_asset(asset_db_id: int, db: Session = Depends(get_db)):
    asset = db.query(Asset).filter(Asset.id == asset_db_id).first()
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")
    return asset


@router.get("/by-asset-id/{asset_id}", response_model=AssetResponse)
def get_asset_by_asset_id(asset_id: str, db: Session = Depends(get_db)):
    asset = db.query(Asset).filter(Asset.asset_id == asset_id).first()
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")
    return asset


@router.put("/{asset_db_id}", response_model=AssetResponse)
def update_asset(asset_db_id: int, update: AssetUpdate, db: Session = Depends(get_db)):
    asset = db.query(Asset).filter(Asset.id == asset_db_id).first()
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")

    update_data = update.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(asset, key, value)
    asset.updated_at = datetime.utcnow()

    db.commit()
    db.refresh(asset)
    return asset


@router.delete("/{asset_db_id}")
def delete_asset(asset_db_id: int, db: Session = Depends(get_db)):
    asset = db.query(Asset).filter(Asset.id == asset_db_id).first()
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")
    db.delete(asset)
    db.commit()
    return {"detail": "Asset deleted"}


@router.post("/{asset_db_id}/assign", response_model=AssetResponse)
def assign_asset(asset_db_id: int, data: AssetAssign, db: Session = Depends(get_db)):
    asset = db.query(Asset).filter(Asset.id == asset_db_id).first()
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")

    employee = db.query(Employee).filter(Employee.id == data.employee_id).first()
    if not employee:
        raise HTTPException(status_code=404, detail="Employee not found")

    old_user_id = asset.current_user_id
    asset.current_user_id = data.employee_id
    if data.location_id:
        asset.current_location_id = data.location_id
    if data.project_id:
        asset.project_id = data.project_id
    asset.status = "assigned"
    asset.updated_at = datetime.utcnow()

    create_movement(
        db, asset.id, "assigned",
        from_user_id=old_user_id, to_user_id=data.employee_id,
        from_status="available", to_status="assigned",
        purpose=data.purpose, remarks=data.remarks
    )
    db.commit()
    db.refresh(asset)
    return asset


@router.post("/{asset_db_id}/transfer", response_model=AssetResponse)
def transfer_asset(asset_db_id: int, data: AssetTransfer, db: Session = Depends(get_db)):
    asset = db.query(Asset).filter(Asset.id == asset_db_id).first()
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")

    new_user = db.query(Employee).filter(Employee.id == data.to_employee_id).first()
    if not new_user:
        raise HTTPException(status_code=404, detail="Employee not found")

    old_user_id = asset.current_user_id
    asset.current_user_id = data.to_employee_id
    asset.updated_at = datetime.utcnow()

    create_movement(
        db, asset.id, "transferred",
        from_user_id=old_user_id, to_user_id=data.to_employee_id,
        from_status="assigned", to_status="assigned",
        purpose=data.purpose, remarks=data.remarks
    )
    db.commit()
    db.refresh(asset)
    return asset


@router.post("/{asset_db_id}/return", response_model=AssetResponse)
def return_asset(asset_db_id: int, data: AssetReturn, db: Session = Depends(get_db)):
    asset = db.query(Asset).filter(Asset.id == asset_db_id).first()
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")

    old_user_id = asset.current_user_id
    asset.current_user_id = None
    if data.location_id:
        asset.current_location_id = data.location_id
    asset.status = "available"
    asset.updated_at = datetime.utcnow()

    create_movement(
        db, asset.id, "returned",
        from_user_id=old_user_id,
        from_status="assigned", to_status="available",
        remarks=data.remarks
    )
    db.commit()
    db.refresh(asset)
    return asset


@router.post("/{asset_db_id}/assign-drone", response_model=AssetResponse)
def assign_to_drone(asset_db_id: int, data: AssetDroneAssign, db: Session = Depends(get_db)):
    asset = db.query(Asset).filter(Asset.id == asset_db_id).first()
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")

    old_drone_id = asset.current_drone_id
    asset.current_drone_id = data.drone_id
    asset.status = "in_drone"
    asset.updated_at = datetime.utcnow()

    create_movement(
        db, asset.id, "installed_drone",
        from_drone_id=old_drone_id, to_drone_id=data.drone_id,
        from_status="assigned", to_status="in_drone",
        purpose=data.purpose, remarks=data.remarks
    )
    db.commit()
    db.refresh(asset)
    return asset


@router.post("/{asset_db_id}/remove-drone", response_model=AssetResponse)
def remove_from_drone(asset_db_id: int, data: AssetReturn, db: Session = Depends(get_db)):
    asset = db.query(Asset).filter(Asset.id == asset_db_id).first()
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")

    old_drone_id = asset.current_drone_id
    asset.current_drone_id = None
    asset.status = "available"
    asset.updated_at = datetime.utcnow()

    create_movement(
        db, asset.id, "removed_drone",
        from_drone_id=old_drone_id,
        from_status="in_drone", to_status="available",
        remarks=data.remarks
    )
    db.commit()
    db.refresh(asset)
    return asset


@router.post("/{asset_db_id}/report-missing", response_model=AssetResponse)
def report_missing(asset_db_id: int, data: AssetReport, db: Session = Depends(get_db)):
    asset = db.query(Asset).filter(Asset.id == asset_db_id).first()
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")

    old_status = asset.status
    asset.status = "missing"
    asset.remarks = data.description or asset.remarks
    asset.updated_at = datetime.utcnow()

    create_movement(
        db, asset.id, "reported_missing",
        from_status=old_status, to_status="missing",
        remarks=data.remarks
    )
    db.commit()
    db.refresh(asset)
    return asset


@router.post("/{asset_db_id}/report-damaged", response_model=AssetResponse)
def report_damaged(asset_db_id: int, data: AssetReport, db: Session = Depends(get_db)):
    asset = db.query(Asset).filter(Asset.id == asset_db_id).first()
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")

    old_status = asset.status
    asset.status = "damaged"
    asset.condition_type = "poor"
    asset.remarks = data.description or asset.remarks
    asset.updated_at = datetime.utcnow()

    create_movement(
        db, asset.id, "reported_damaged",
        from_status=old_status, to_status="damaged",
        remarks=data.remarks
    )
    db.commit()
    db.refresh(asset)
    return asset


@router.get("/{asset_db_id}/history", response_model=list[MovementResponse])
def get_asset_history(asset_db_id: int, db: Session = Depends(get_db)):
    asset = db.query(Asset).filter(Asset.id == asset_db_id).first()
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")
    return asset.movements
