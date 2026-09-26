import os
import httpx
import logging
from datetime import datetime

logger = logging.getLogger(__name__)

DISCORD_WEBHOOK_URL = os.getenv("DISCORD_WEBHOOK_URL")
TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
TELEGRAM_CHAT_ID = os.getenv("TELEGRAM_CHAT_ID")

async def notify_discord(service_name: str, old_limit: str, new_limit: str, url: str, alert_type: str, timestamp: datetime):
    if not DISCORD_WEBHOOK_URL:
        return
    
    color = 16711680 if alert_type == 'TIER_DOWNGRADE' else 16753920
    
    payload = {
        "embeds": [
            {
                "title": f"🚨 Tier Alert: {service_name}",
                "description": f"A change was detected in the free tier limits for **{service_name}**.",
                "url": url or "https://freetier.radar",
                "color": color,
                "fields": [
                    {"name": "Old Limit", "value": old_limit or "Unknown", "inline": True},
                    {"name": "New Limit", "value": new_limit or "Unknown", "inline": True}
                ],
                "footer": {"text": f"Detected at {timestamp.isoformat()}"}
            }
        ]
    }
    
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.post(DISCORD_WEBHOOK_URL, json=payload, timeout=10.0)
            resp.raise_for_status()
    except Exception as e:
        logger.error(f"Failed to send Discord webhook: {e}")

async def notify_telegram(service_name: str, old_limit: str, new_limit: str, url: str, alert_type: str, timestamp: datetime):
    if not TELEGRAM_BOT_TOKEN or not TELEGRAM_CHAT_ID:
        return
    
    text = (
        f"🚨 *Tier Alert: {service_name}*\n\n"
        f"A change was detected in the free tier limits.\n"
        f"*Old Limit:* {old_limit or 'Unknown'}\n"
        f"*New Limit:* {new_limit or 'Unknown'}\n"
        f"[Service URL]({url or 'https://freetier.radar'})"
    )
    
    payload = {
        "chat_id": TELEGRAM_CHAT_ID,
        "text": text,
        "parse_mode": "Markdown"
    }
    
    url_req = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.post(url_req, json=payload, timeout=10.0)
            resp.raise_for_status()
    except Exception as e:
        logger.error(f"Failed to send Telegram message: {e}")

async def send_tier_alert(service_name: str, old_limit: str, new_limit: str, url: str, alert_type: str, timestamp: datetime):
    """Dispatches asynchronous tier alerts to all configured platforms."""
    # Ensure they don't block by triggering them safely, although usually we await them in tasks
    await notify_discord(service_name, old_limit, new_limit, url, alert_type, timestamp)
    await notify_telegram(service_name, old_limit, new_limit, url, alert_type, timestamp)
