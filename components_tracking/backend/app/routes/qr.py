from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse, HTMLResponse
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Asset
from app.services.qr_service import generate_qr_image, generate_barcode_image

router = APIRouter(prefix="/qr", tags=["QR Codes"])


@router.get("/{asset_id}/image")
def get_qr_image(asset_id: str, db: Session = Depends(get_db)):
    asset = db.query(Asset).filter(Asset.asset_id == asset_id).first()
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")
    buf = generate_qr_image(asset.asset_id)
    return StreamingResponse(buf, media_type="image/png", headers={
        "Content-Disposition": f"inline; filename=QR_{asset.asset_id}.png"
    })


@router.get("/{asset_id}/barcode")
def get_barcode_image(asset_id: str, db: Session = Depends(get_db)):
    asset = db.query(Asset).filter(Asset.asset_id == asset_id).first()
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")

    assigned_to = asset.current_user.name if asset.current_user else ""
    buf = generate_barcode_image(
        asset_id=asset.asset_id,
        asset_name=asset.name,
        assigned_to=assigned_to,
        status=asset.status,
    )
    return StreamingResponse(buf, media_type="image/png", headers={
        "Content-Disposition": f"inline; filename=BAR_{asset.asset_id}.png"
    })


@router.get("/{asset_id}/view")
def get_qr_view_page(asset_id: str, db: Session = Depends(get_db)):
    asset = db.query(Asset).filter(Asset.asset_id == asset_id).first()
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")

    user_name = asset.current_user.name if asset.current_user else "Unassigned"
    drone_name = asset.current_drone.name if asset.current_drone else None
    location_name = asset.current_location.name if asset.current_location else None
    project_name = asset.project.name if asset.project else None

    status_colors = {
        "available": "#16a34a",
        "assigned": "#2563eb",
        "in_drone": "#9333ea",
        "testing": "#4f46e5",
        "maintenance": "#ea580c",
        "missing": "#dc2626",
        "damaged": "#db2777",
    }
    status_color = status_colors.get(asset.status, "#6b7280")

    extra_rows = ""
    if drone_name:
        extra_rows += f"""<tr><td>Drone</td><td>{drone_name}</td></tr>"""
    if location_name:
        extra_rows += f"""<tr><td>Location</td><td>{location_name}</td></tr>"""
    if project_name:
        extra_rows += f"""<tr><td>Project</td><td>{project_name}</td></tr>"""
    if asset.serial_number:
        extra_rows += f"""<tr><td>Serial</td><td>{asset.serial_number}</td></tr>"""
    if asset.model:
        extra_rows += f"""<tr><td>Model</td><td>{asset.model}</td></tr>"""
    if asset.remarks:
        extra_rows += f"""<tr><td>Remarks</td><td>{asset.remarks}</td></tr>"""

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{asset.asset_id} - Asset Details</title>
<style>
* {{ margin: 0; padding: 0; box-sizing: border-box; }}
body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    background: #f1f5f9; min-height: 100vh; padding: 16px; }}
.card {{ background: white; border-radius: 16px; padding: 24px; max-width: 480px;
    margin: 0 auto; box-shadow: 0 4px 24px rgba(0,0,0,0.08); }}
.header {{ text-align: center; margin-bottom: 20px; }}
.asset-id {{ font-size: 32px; font-weight: 800; font-family: monospace; letter-spacing: 2px; }}
.asset-name {{ font-size: 18px; color: #475569; margin-top: 4px; }}
.badge {{ display: inline-block; padding: 4px 14px; border-radius: 20px; color: white;
    font-size: 13px; font-weight: 600; text-transform: uppercase; margin-top: 12px; }}
.category {{ display: inline-block; padding: 4px 12px; border-radius: 8px;
    background: #f1f5f9; color: #475569; font-size: 13px; margin-top: 8px; }}
table {{ width: 100%; border-collapse: collapse; margin-top: 16px; }}
td {{ padding: 10px 12px; border-bottom: 1px solid #f1f5f9; font-size: 14px; }}
td:first-child {{ color: #94a3b8; font-weight: 500; width: 120px; }}
td:last-child {{ color: #1e293b; }}
.footer {{ text-align: center; margin-top: 20px; font-size: 12px; color: #94a3b8; }}
</style>
</head>
<body>
<div class="card">
    <div class="header">
        <div class="asset-id">{asset.asset_id}</div>
        <div class="asset-name">{asset.name}</div>
        <span class="badge" style="background: {status_color}">{asset.status}</span>
        <br><span class="category">{asset.category}</span>
    </div>
    <table>
        <tr><td>Assigned To</td><td>{user_name}</td></tr>
        <tr><td>Condition</td><td>{asset.condition_type}</td></tr>
        <tr><td>Updated</td><td>{asset.updated_at.strftime('%d %b %Y %H:%M') if asset.updated_at else 'N/A'}</td></tr>
        {extra_rows}
    </table>
    <div class="footer">QR Asset Tracking System</div>
</div>
</body>
</html>"""
    return HTMLResponse(content=html)


@router.get("/{asset_id}/print")
def get_qr_print_page(asset_id: str, db: Session = Depends(get_db)):
    asset = db.query(Asset).filter(Asset.asset_id == asset_id).first()
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")

    import base64
    buf = generate_qr_image(asset.asset_id)
    qr_b64 = base64.b64encode(buf.read()).decode("utf-8")

    html = f"""<!DOCTYPE html>
<html>
<head>
<title>Print QR - {asset.asset_id}</title>
<style>
@page {{ size: auto; margin: 10mm; }}
body {{ font-family: Arial, sans-serif; display: flex; justify-content: center; padding: 20px; }}
.qr-card {{
    border: 2px solid #333;
    border-radius: 12px;
    padding: 24px;
    text-align: center;
    width: 280px;
    page-break-inside: avoid;
}}
.qr-card img {{ width: 180px; height: 180px; }}
.asset-id {{ font-size: 28px; font-weight: bold; margin: 12px 0 4px; font-family: monospace; }}
.asset-name {{ font-size: 16px; color: #555; margin-bottom: 4px; }}
.asset-category {{ font-size: 13px; color: #888; margin-bottom: 8px; }}
.asset-serial {{ font-size: 12px; color: #999; }}
.btn-print {{ margin-top: 16px; padding: 10px 24px; background: #2563eb; color: white;
    border: none; border-radius: 8px; cursor: pointer; font-size: 14px; }}
.btn-print:hover {{ background: #1d4ed8; }}
@media print {{
    .btn-print {{ display: none; }}
    body {{ padding: 0; }}
}}
</style>
</head>
<body>
<div class="qr-card">
    <img src="data:image/png;base64,{qr_b64}" alt="QR {asset.asset_id}" />
    <div class="asset-id">{asset.asset_id}</div>
    <div class="asset-name">{asset.name}</div>
    <div class="asset-category">{asset.category}</div>
    <div class="asset-serial">SN: {asset.serial_number or 'N/A'}</div>
    <button class="btn-print" onclick="window.print()">Print QR Label</button>
</div>
</body>
</html>"""
    return HTMLResponse(content=html)
