import httpx
from bs4 import BeautifulSoup
import asyncio
import logging
import json
from typing import Optional

logger = logging.getLogger(__name__)

async def fetch_html(url: str, client: httpx.AsyncClient) -> str:
    try:
        response = await client.get(url, timeout=15.0, follow_redirects=True)
        response.raise_for_status()
        return response.text
    except Exception as e:
        logger.error(f"Failed to fetch {url}: {e}")
        return ""

def extract_next_data(html: str) -> Optional[dict]:
    """Extracts and parses Next.js hydration data if present."""
    soup = BeautifulSoup(html, 'html.parser')
    script_tag = soup.find('script', id='__NEXT_DATA__', type='application/json')
    if script_tag and script_tag.string:
        try:
            return json.loads(script_tag.string)
        except json.JSONDecodeError as e:
            logger.warning(f"Failed to parse __NEXT_DATA__ json: {e}")
    return None

async def scrape_supabase(client: httpx.AsyncClient) -> dict:
    url = "https://supabase.com/pricing"
    html = await fetch_html(url, client)
    if not html: return {}
    
    # Try next.js data first if applicable (Supabase uses Next.js)
    next_data = extract_next_data(html)
    if next_data:
        logger.info("Supabase: Found __NEXT_DATA__, attempting to extract pricing props...")
        # Since exact structure changes, we log and fall back safely if we can't find it
        # Real-world parser would deeply inspect `next_data["props"]["pageProps"]...`
        pass
        
    soup = BeautifulSoup(html, 'html.parser')
    free_tier_data = []
    
    free_card = soup.find(string=lambda text: text and text.strip().lower() == "free")
    if free_card:
        parent = free_card.find_parent("div", class_=lambda c: c and 'pricing' in c.lower())
        if parent:
            limits = parent.find_all("li")
            free_tier_data = [li.get_text(strip=True) for li in limits if li.get_text(strip=True)]
    
    raw_text = "\n".join(free_tier_data)
    
    if not raw_text or len(raw_text) < 10:
        logger.warning("Supabase: Layout change detected or limits too short. Returning empty to avoid data corruption.")
        return {}

    return {
        "service_name": "Supabase",
        "raw_text": raw_text,
        "url": url
    }

async def scrape_vercel(client: httpx.AsyncClient) -> dict:
    url = "https://vercel.com/pricing"
    html = await fetch_html(url, client)
    if not html: return {}
    
    next_data = extract_next_data(html)
    if next_data:
        logger.info("Vercel: Found __NEXT_DATA__")
    
    soup = BeautifulSoup(html, 'html.parser')
    free_tier_data = []
    
    hobby_card = soup.find(string=lambda text: text and text.strip().lower() == "hobby")
    if hobby_card:
        parent = hobby_card.find_parent("div")
        if parent:
            # Look for adjacent lists
            ul = parent.find_next_sibling("ul")
            if ul:
                limits = ul.find_all("li")
                free_tier_data = [li.get_text(strip=True) for li in limits]
    
    raw_text = "\n".join(free_tier_data)
    if not raw_text or len(raw_text) < 10:
        logger.warning("Vercel: Failed to find valid Hobby tier limits in DOM.")
        return {}

    return {
        "service_name": "Vercel",
        "raw_text": raw_text,
        "url": url
    }

async def scrape_render(client: httpx.AsyncClient) -> dict:
    url = "https://render.com/pricing"
    html = await fetch_html(url, client)
    if not html: return {}
    
    soup = BeautifulSoup(html, 'html.parser')
    free_tier_data = []
    
    free_plan = soup.find(string=lambda t: t and "Free" in t)
    if free_plan:
        parent = free_plan.find_parent("div")
        if parent:
            limits = parent.find_parent("div").find_all("li")
            free_tier_data = [li.get_text(strip=True) for li in limits]
            
    raw_text = "\n".join(free_tier_data)
    if not raw_text or len(raw_text) < 5:
        logger.warning("Render: Failed to find valid Free tier limits in DOM.")
        return {}

    return {
        "service_name": "Render",
        "raw_text": raw_text,
        "url": url
    }

async def run_targeted_scrapers() -> list[dict]:
    """
    Runs all targeted web scrapers to fetch real-time pricing data directly 
    from the provider websites. Returns robust dictionaries.
    """
    logger.info("Running targeted pricing scrapers...")
    results = []
    async with httpx.AsyncClient(headers={"User-Agent": "FreeTierRadar/1.0"}) as client:
        tasks = [
            scrape_supabase(client),
            scrape_vercel(client),
            scrape_render(client)
        ]
        scraped_data = await asyncio.gather(*tasks, return_exceptions=True)
        
        for data in scraped_data:
            if isinstance(data, dict) and data:
                # Sanity check validation schema before yielding
                if data.get("raw_text") and data.get("service_name"):
                    results.append(data)
                else:
                    logger.warning(f"Discarding invalid scraped data block: {data}")
            elif isinstance(data, Exception):
                logger.error(f"Targeted scraper exception: {data}")
    
    logger.info(f"Targeted scrapers finished. Gathered {len(results)} valid profiles.")
    return results
