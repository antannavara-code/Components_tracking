from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import engine, Base
from app.routes import assets, employees, drones, locations, projects, auth, dashboard, qr

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="QR Asset & Component Tracking System",
    description="Track hardware assets with QR codes",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(assets.router)
app.include_router(employees.router)
app.include_router(drones.router)
app.include_router(locations.router)
app.include_router(projects.router)
app.include_router(dashboard.router)
app.include_router(qr.router)


@app.get("/")
def root():
    return {"message": "QR Asset Tracking API is running"}
