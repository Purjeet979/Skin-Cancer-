import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "app.db")

# MOCK / SEED DATASET FOR DERMATOLOGIST DIRECTORY (SIMULATED FOR DEMO, NOT SCRAPED FROM REAL DIRECTORY)
MOCK_DERMATOLOGISTS = [
    {
        "id": 1,
        "name": "Dr. Sarah Lin, MD (Mock Profile)",
        "specialty": "Dermato-Oncology & Melanoma Specialist",
        "clinic": "Metro Dermatology & Skin Cancer Center (Mock Clinic)",
        "address": "742 Evergreen Ave, Suite 300, San Francisco, CA",
        "phone": "+1 (555) 019-2831",
        "rating": 4.9,
        "lat": 37.7749,
        "lon": -122.4194
    },
    {
        "id": 2,
        "name": "Dr. Marcus Vance, MD (Mock Profile)",
        "specialty": "Surgical Dermatology & Mohs Micrographic Surgery",
        "clinic": "City Skin & Laser Institute (Mock Clinic)",
        "address": "120 Market Street, 4th Floor, San Francisco, CA",
        "phone": "+1 (555) 014-8822",
        "rating": 4.8,
        "lat": 37.7833,
        "lon": -122.4167
    },
    {
        "id": 3,
        "name": "Dr. Elena Rostova, MD (Mock Profile)",
        "specialty": "General & Pediatric Dermatology",
        "clinic": "Bayview Medical Dermatology (Mock Clinic)",
        "address": "450 Sutter St, Suite 1200, San Francisco, CA",
        "phone": "+1 (555) 017-9943",
        "rating": 4.7,
        "lat": 37.7895,
        "lon": -122.4082
    },
    {
        "id": 4,
        "name": "Dr. James Thorne, MD (Mock Profile)",
        "specialty": "Cutaneous Oncology & Lesion Screening",
        "clinic": "Pacific Skin Cancer Center (Mock Clinic)",
        "address": "900 Hyde St, Suite 50, San Francisco, CA",
        "phone": "+1 (555) 012-3377",
        "rating": 4.9,
        "lat": 37.7912,
        "lon": -122.4160
    }
]

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Create dermatologists table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS dermatologists (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            specialty TEXT NOT NULL,
            clinic TEXT NOT NULL,
            address TEXT NOT NULL,
            phone TEXT NOT NULL,
            rating REAL NOT NULL,
            lat REAL NOT NULL,
            lon REAL NOT NULL,
            is_mock_data INTEGER DEFAULT 1
        )
    """)
    
    # Create referrals table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS referrals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            patient_name TEXT NOT NULL,
            patient_contact TEXT NOT NULL,
            dermatologist_id INTEGER NOT NULL,
            lesion_class TEXT NOT NULL,
            risk_level TEXT NOT NULL,
            status TEXT DEFAULT 'PENDING',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (dermatologist_id) REFERENCES dermatologists (id)
        )
    """)
    
    # Seed dermatologists if empty
    cursor.execute("SELECT COUNT(*) FROM dermatologists")
    if cursor.fetchone()[0] == 0:
        for doc in MOCK_DERMATOLOGISTS:
            cursor.execute("""
                INSERT INTO dermatologists (id, name, specialty, clinic, address, phone, rating, lat, lon, is_mock_data)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
            """, (doc["id"], doc["name"], doc["specialty"], doc["clinic"], doc["address"], doc["phone"], doc["rating"], doc["lat"], doc["lon"]))
            
    conn.commit()
    conn.close()

def get_db_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

if __name__ == "__main__":
    init_db()
    print("Database initialized successfully at:", DB_PATH)
