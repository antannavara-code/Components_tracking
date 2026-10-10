import io
import qrcode
import barcode
from barcode.writer import ImageWriter
from qrcode.image.pil import PilImage
from PIL import Image, ImageDraw, ImageFont


BASE_URL = "http://127.0.0.1:8000"


def set_base_url(url: str):
    global BASE_URL
    BASE_URL = url


def generate_qr_image(asset_id: str) -> io.BytesIO:
    qr = qrcode.QRCode(
        version=2,
        error_correction=qrcode.constants.ERROR_CORRECT_M,
        box_size=10,
        border=2,
    )
    qr.add_data(f"{BASE_URL}/qr/{asset_id}/view")
    qr.make(fit=True)
    img: PilImage = qr.make_image(fill_color="black", back_color="white")
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    buf.seek(0)
    return buf


def generate_barcode_image(
    asset_id: str,
    asset_name: str = "",
    assigned_to: str = "",
    status: str = "",
) -> io.BytesIO:
    writer = ImageWriter()
    writer.set_options({
        "module_width": 0.3,
        "module_height": 15.0,
        "font_size": 10,
        "text_distance": 5.0,
        "quiet_zone": 2.0,
    })

    code128 = barcode.get("code128", asset_id, writer=writer)
    barcode_buf = io.BytesIO()
    code128.write(barcode_buf)
    barcode_buf.seek(0)

    barcode_img = Image.open(barcode_buf).convert("RGB")

    text_height = 0
    lines = []
    if asset_name:
        lines.append(asset_name)
    if assigned_to:
        lines.append(f"To: {assigned_to}")
    if status:
        lines.append(status.upper())

    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 14)
        small_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 12)
    except (OSError, IOError):
        font = ImageFont.load_default()
        small_font = font

    line_height = 18
    text_height = len(lines) * line_height + 10

    total_width = max(barcode_img.width, 300)
    total_height = barcode_img.height + text_height + 20

    canvas = Image.new("RGB", (total_width, total_height), "white")

    x_offset = (total_width - barcode_img.width) // 2
    canvas.paste(barcode_img, (x_offset, 10))

    draw = ImageDraw.Draw(canvas)
    y = barcode_img.height + 15
    for i, line in enumerate(lines):
        f = font if i == 0 else small_font
        bbox = draw.textbbox((0, 0), line, font=f)
        tw = bbox[2] - bbox[0]
        x = (total_width - tw) // 2
        draw.text((x, y), line, fill="black", font=f)
        y += line_height

    buf = io.BytesIO()
    canvas.save(buf, format="PNG")
    buf.seek(0)
    return buf


def generate_qr_svg(asset_id: str) -> str:
    qr = qrcode.QRCode(
        version=2,
        error_correction=qrcode.constants.ERROR_CORRECT_M,
        box_size=10,
        border=2,
    )
    qr.add_data(f"{BASE_URL}/qr/{asset_id}/view")
    qr.make(fit=True)
    factory = qrcode.image.svg.SvgPathImage
    img = qr.make_image(image_factory=factory)
    buf = io.BytesIO()
    img.save(buf)
    return buf.getvalue().decode("utf-8")
