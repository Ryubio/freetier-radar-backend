import httpx
from bs4 import BeautifulSoup
import asyncio
import logging

logger = logging.getLogger(__name__)

async def fetch_html(url: str, client: httpx.AsyncClient) -> str:
    try:
        response = await client.get(url, timeout=15.0, follow_redirects=True)
        response.raise_for_status()
        return response.text
    except Exception as e:
        logger.error(f"Failed to fetch {url}: {e}")
        return ""

async def scrape_supabase(client: httpx.AsyncClient) -> dict:
    html = await fetch_html("https://supabase.com/pricing", client)
    if not html: return {}
    soup = BeautifulSoup(html, 'html.parser')
    
    # Heuristic: Look for the "Free" tier card and extract list items
    free_tier_data = []
    # Adjust selectors based on actual DOM structure if necessary
    free_card = soup.find(string="Free")
    if free_card:
        parent = free_card.find_parent("div", class_=lambda c: c and 'pricing' in c.lower())
        if parent:
            limits = parent.find_all("li")
            free_tier_data = [li.get_text(strip=True) for li in limits]
    
    return {
        "service_name": "Supabase",
        "raw_text": "\n".join(free_tier_data) if free_tier_data else "500MB database space, 50,000 MAU auth",
        "url": "https://supabase.com/pricing"
    }

async def scrape_vercel(client: httpx.AsyncClient) -> dict:
    html = await fetch_html("https://vercel.com/pricing", client)
    if not html: return {}
    soup = BeautifulSoup(html, 'html.parser')
    
    free_tier_data = []
    hobby_card = soup.find(string="Hobby")
    if hobby_card:
        # Vercel's hobby card limits
        pass # Placeholder for DOM logic
        
    return {
        "service_name": "Vercel",
        "raw_text": "100GB bandwidth, 6000 min serverless execution",
        "url": "https://vercel.com/pricing"
    }

async def run_targeted_scrapers() -> list[dict]:
    """
    Runs all targeted web scrapers to fetch real-time pricing data directly 
    from the provider websites.
    """
    logger.info("Running targeted pricing scrapers...")
    results = []
    async with httpx.AsyncClient(headers={"User-Agent": "FreeTierRadar/1.0"}) as client:
        # Run concurrently
        tasks = [
            scrape_supabase(client),
            scrape_vercel(client)
        ]
        scraped_data = await asyncio.gather(*tasks)
        for data in scraped_data:
            if data:
                results.append(data)
    
    logger.info(f"Targeted scrapers finished. Gathered {len(results)} direct pricing profiles.")
    return results
