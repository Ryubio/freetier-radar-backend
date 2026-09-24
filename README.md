# ⚡ FreeTier Radar - Backend & Scraper Engine

[![FastAPI](https://img.shields.io/badge/FastAPI-0.110+-009688.svg?style=flat&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3.11+-3776AB.svg?style=flat&logo=python&logoColor=white)](https://python.org)
[![SQLite](https://img.shields.io/badge/Database-SQLite%20%2F%20SQLModel-003B57.svg?style=flat&logo=sqlite&logoColor=white)](https://sqlmodel.tiangolo.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**FreeTier Radar Backend**, geliştirici araçları, bulut servisleri ve yapay zeka sağlayıcılarının ücretsiz katman (free-tier) kotalarını dinamik olarak takip eden, kotası düşürülen (deprecate edilen) veya kısıtlanan servisleri tespit eden kurumsal seviye bir veri kazıma ve API servisidir.

---

## 🎯 Özellikler

* **Çift Katmanlı Veri Kazıma (Dual-layer Scraper Engine):**
  * **GitHub Topluluk Kaynağı:** `ripienaar/free-for-dev` deposunu asenkron ayrıştırıp 300+ servisi kategorize eder.
  * **Hedefli Kazıyıcılar (Targeted Scrapers):** Supabase, Vercel, Render gibi kritik platformların resmi fiyatlandırma sayfalarını `BeautifulSoup4` ve `httpx` ile doğrudan kazır.
* **Akıllı Diff & Deprecation Motoru:**
  * Servislerin önceki kotalarıyla yeni kotalarını SHA-256 hash'leri ve regex desenleriyle karşılaştırır.
  * Kota düşüşlerini (`100GB -> 50GB` gibi) yakalar ve `old_limit` / `new_limit` farklarını `TierAlert` modeliyle mobil uygulamaya sunar.
* **Arka Plan Zamanlayıcı (APScheduler):**
  * Servis kotalarını 12 saatlik aralıklarla otomatik doğrular ve veritabanını güncel tutar.
* **Canlı Tetikleyici (Manual Trigger):**
  * `POST /api/v1/sync` endpoint'i üzerinden anında manuel tarama başlatma imkanı.

---

## 🛠️ Mimari & Teknolojiler

* **Framework:** FastAPI
* **Veritabanı & ORM:** SQLite & SQLModel (SQLAlchemy 2.0 tabanlı)
* **Web Kazıma:** `httpx` (Asenkron HTTP istemcisi), `beautifulsoup4`
* **Görev Zamanlayıcı:** `APScheduler` (BackgroundScheduler)
* **Sunucu:** Uvicorn (ASGI)

---

## 🚀 Yerel Kurulum & Çalıştırma

Projeyi yerel ortamınızda ayağa kaldırmak için:

```bash
# 1. Repoyu klonlayın
git clone [https://github.com/Ryubio/freetier-radar-backend.git](https://github.com/Ryubio/freetier-radar-backend.git)
cd freetier-radar-backend

# 2. Sanal ortamı kurun ve bağımlılıkları yükleyin
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 3. Veritabanını oluşturun ve ilk verileri tohumlayın
python3 seed_data.py

# 4. Sunucuyu başlatın
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
📡 REST API Endpoint'leriMetotEndpointAçıklamaGET/api/v1/servicesTüm ücretsiz servisleri listeler (category, no_credit_card, search filtreleri desteklenir).GET/api/v1/services/{id}Belirli bir servisin detaylı kota bilgilerini getirir.GET/api/v1/alerts/deprecationsKota düşüşü veya kısıtlama yaşayan servislerin eski/yeni limit farklarını listeler.POST/api/v1/syncKazıyıcı motoru manuel olarak tetikler ve verileri günceller.GET/docsEtkileşimli Swagger UI dökümantasyonu.🌐 Dağıtım (Production)Bu backend, Render.com üzerinde ücretsiz container mimarisinde 7/24 çalışacak şekilde yapılandırılmıştır.Build Command: pip install -r requirements.txtStart Command: uvicorn main:app --host 0.0.0.0 --port $PORT
