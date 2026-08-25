from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse, HTMLResponse
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Asset
from app.services.qr_service import generate_qr_image

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
