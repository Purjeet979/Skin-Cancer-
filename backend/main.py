import os
import sys
import math
import shutil
import sqlite3
from typing import Optional, List
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# Add model-training directory to sys.path to access gradcam.py
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_TRAINING_DIR = os.path.join(BASE_DIR, "model-training")
if MODEL_TRAINING_DIR not in sys.path:
    sys.path.append(MODEL_TRAINING_DIR)

from gradcam import get_gradcam_explanation
from database import init_db, get_db_connection

init_db()

app = FastAPI(
    title="DermaScan AI Backend API",
    description="Skin Cancer Screening, Grad-CAM Explainability & Referral Workflow API (Mock/Seed Dataset)"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOADS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "uploads")
os.makedirs(UPLOADS_DIR, exist_ok=True)

app.mount("/static", StaticFiles(directory=UPLOADS_DIR), name="static")

SUSPICIOUS_CLASSES = ["mel", "bcc", "akiec", "melanoma", "basal cell carcinoma", "actinic keratosis"]

def calculate_distance(lat1, lon1, lat2, lon2):
    # Haversine distance in kilometers
    R = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return round(R * c, 2)

def fetch_nearest_dermatologists(user_lat=37.7749, user_lon=-122.4194, limit=3):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM dermatologists")
    rows = cursor.fetchall()
    conn.close()

    docs = []
    for r in rows:
        d = dict(r)
        d["distance_km"] = calculate_distance(user_lat, user_lon, d["lat"], d["lon"])
        d["data_type"] = "MOCK_SEED_DATA"
        docs.append(d)

    docs.sort(key=lambda x: x["distance_km"])
    return docs[:limit]

class ReferralRequest(BaseModel):
    patient_name: str
    patient_contact: str
    dermatologist_id: int
    lesion_class: str
    risk_level: str

@app.get("/")
def root():
    return {
        "service": "DermaScan AI Backend API",
        "status": "ONLINE",
        "mock_dataset_disclaimer": "Dermatologist directory is mock/seed data for demonstration purposes."
    }

@app.post("/screen")
async def screen_lesion(
    file: UploadFile = File(...),
    user_lat: float = Form(37.7749),
    user_lon: float = Form(-122.4194)
):
    # Save uploaded file
    file_path = os.path.join(UPLOADS_DIR, file.filename)
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # Run model + Grad-CAM
    output_heatmap_name = f"gradcam_{file.filename}"
    output_heatmap_path = os.path.join(UPLOADS_DIR, output_heatmap_name)
    
    explanation = get_gradcam_explanation(file_path, output_path=output_heatmap_path)
    
    pred_class_lower = str(explanation["class"]).lower()
    is_suspicious = any(sc in pred_class_lower for sc in SUSPICIOUS_CLASSES)
    
    if is_suspicious:
        risk_level = "HIGH" if "mel" in pred_class_lower else "MEDIUM"
        referral_recommended = True
        recommended_specialists = fetch_nearest_dermatologists(user_lat, user_lon, limit=3)
    else:
        risk_level = "LOW"
        referral_recommended = False
        recommended_specialists = []

    heatmap_url = f"/static/{output_heatmap_name}"

    return {
        "class": explanation["class"],
        "class_id": explanation["class_id"],
        "confidence": explanation["confidence"],
        "risk_level": risk_level,
        "referral_recommended": referral_recommended,
        "heatmap_url": heatmap_url,
        "recommended_specialists": recommended_specialists,
        "mock_data_notice": "Dermatologist suggestions originate from a mock/seed dataset for demonstration."
    }

@app.get("/dermatologists")
def get_dermatologists(user_lat: float = 37.7749, user_lon: float = -122.4194):
    docs = fetch_nearest_dermatologists(user_lat, user_lon, limit=10)
    return {
        "count": len(docs),
        "data_disclaimer": "MOCK / SEED DATASET FOR DEMO PURPOSES ONLY (NOT SCRAPED FROM REAL DIRECTORY)",
        "dermatologists": docs
    }

@app.post("/referral")
def create_referral(req: ReferralRequest):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Verify doctor exists
    cursor.execute("SELECT id, name FROM dermatologists WHERE id = ?", (req.dermatologist_id,))
    doc = cursor.fetchone()
    if not doc:
        conn.close()
        raise HTTPException(status_code=404, detail="Dermatologist not found in database.")
        
    cursor.execute("""
        INSERT INTO referrals (patient_name, patient_contact, dermatologist_id, lesion_class, risk_level, status)
        VALUES (?, ?, ?, ?, ?, 'BOOKED')
    """, (req.patient_name, req.patient_contact, req.dermatologist_id, req.lesion_class, req.risk_level))
    
    referral_id = cursor.lastrowid
    conn.commit()
    conn.close()

    return {
        "status": "SUCCESS",
        "referral_id": referral_id,
        "message": f"Referral appointment with {doc['name']} booked successfully.",
        "booking_details": {
            "patient_name": req.patient_name,
            "dermatologist": doc['name'],
            "lesion_class": req.lesion_class,
            "risk_level": req.risk_level,
            "status": "BOOKED"
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)
