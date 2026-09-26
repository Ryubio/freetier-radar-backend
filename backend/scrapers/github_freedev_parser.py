"""
GitHub free-for-dev Markdown parser.

Fetches https://github.com/ripienaar/free-for-dev README.md, extracts each
service entry, maps it to a ServiceCategory, and returns a list of
ServiceItem objects ready for database upsert.
"""

import httpx
import re
import logging
from typing import List

from models import ServiceItem, ServiceCategory

logger = logging.getLogger(__name__)

MARKDOWN_URL = (
    "https://raw.githubusercontent.com/ripienaar/free-for-dev/master/README.md"
)

# Map free-for-dev section headers -> our category enum.
# Keys are lowercased for case-insensitive matching.
CATEGORY_MAPPING: dict[str, ServiceCategory] = {
    "major cloud providers": ServiceCategory.HOSTING_PAAS,
    "cloud management solutions": ServiceCategory.HOSTING_PAAS,
    "analytics, events and statistics": ServiceCategory.APIS_DEVTOOLS,
    "apis, data, and ml": ServiceCategory.AI_ML,
    "apis, data and ml": ServiceCategory.AI_ML,
    "artifact repos": ServiceCategory.APIS_DEVTOOLS,
    "baas": ServiceCategory.APIS_DEVTOOLS,
    "low-code platform": ServiceCategory.APIS_DEVTOOLS,
    "cdn and protection": ServiceCategory.STORAGE_CDN,
    "ci and cd": ServiceCategory.APIS_DEVTOOLS,
    "ci / cd": ServiceCategory.APIS_DEVTOOLS,
    "cms": ServiceCategory.HOSTING_PAAS,
    "code generation": ServiceCategory.APIS_DEVTOOLS,
    "code quality": ServiceCategory.APIS_DEVTOOLS,
    "code search and browsing": ServiceCategory.APIS_DEVTOOLS,
    "crash and exception handling": ServiceCategory.APIS_DEVTOOLS,
    "data visualization on maps": ServiceCategory.APIS_DEVTOOLS,
    "managed data services": ServiceCategory.DATABASES,
    "dbaas": ServiceCategory.DATABASES,
    "design and ui": ServiceCategory.CREATIVE_ASSETS,
    "design inspiration": ServiceCategory.CREATIVE_ASSETS,
    "dns": ServiceCategory.HOSTING_PAAS,
    "docker related": ServiceCategory.HOSTING_PAAS,
    "domain": ServiceCategory.HOSTING_PAAS,
    "education and learning": ServiceCategory.APIS_DEVTOOLS,
    "email": ServiceCategory.APIS_DEVTOOLS,
    "feature toggles management platforms": ServiceCategory.APIS_DEVTOOLS,
    "font": ServiceCategory.CREATIVE_ASSETS,
    "forms": ServiceCategory.APIS_DEVTOOLS,
    "generative ai": ServiceCategory.AI_ML,
    "iaas": ServiceCategory.HOSTING_PAAS,
    "ide and code editing": ServiceCategory.APIS_DEVTOOLS,
    "international mobile number verification api and sdk": ServiceCategory.AUTH_SECURITY,
    "issue tracking and project management": ServiceCategory.APIS_DEVTOOLS,
    "log management": ServiceCategory.APIS_DEVTOOLS,
    "management system": ServiceCategory.APIS_DEVTOOLS,
    "messaging and streaming": ServiceCategory.APIS_DEVTOOLS,
    "miscellaneous": ServiceCategory.APIS_DEVTOOLS,
    "monitoring": ServiceCategory.APIS_DEVTOOLS,
    "paas": ServiceCategory.HOSTING_PAAS,
    "payment and billing integration": ServiceCategory.APIS_DEVTOOLS,
    "privacy management": ServiceCategory.AUTH_SECURITY,
    "screenshot apis": ServiceCategory.APIS_DEVTOOLS,
    "flutter related and building iosandroid and desktop apps": ServiceCategory.APIS_DEVTOOLS,
    "search": ServiceCategory.APIS_DEVTOOLS,
    "security and pki": ServiceCategory.AUTH_SECURITY,
    "authentication, authorization, and user management": ServiceCategory.AUTH_SECURITY,
    "source code repos": ServiceCategory.APIS_DEVTOOLS,
    "storage and media processing": ServiceCategory.STORAGE_CDN,
    "testing": ServiceCategory.APIS_DEVTOOLS,
    "tunneling, webrtc, web socket servers and other routers": ServiceCategory.HOSTING_PAAS,
    "translation management": ServiceCategory.APIS_DEVTOOLS,
    "visitor session recording": ServiceCategory.APIS_DEVTOOLS,
    "web hosting": ServiceCategory.HOSTING_PAAS,
    "commenting platforms": ServiceCategory.APIS_DEVTOOLS,
    "browser-based hardware emulation": ServiceCategory.APIS_DEVTOOLS,
    "remote desktop tools": ServiceCategory.APIS_DEVTOOLS,
    "game development": ServiceCategory.APIS_DEVTOOLS,
    "other free resources": ServiceCategory.APIS_DEVTOOLS,
}

# Regex for markdown list items: `  * [Name](url) — description`
# Supports *, -, and various dash/colon separators after the link.
_ENTRY_RE = re.compile(
    r"^[*\-]\s+"           # leading bullet
    r"\[(.+?)\]"           # [Service Name]
    r"\((.+?)\)"           # (url)
    r"\s*[-—–|:]+\s*"     # separator (em-dash, en-dash, pipe, colon)
    r"(.+)$"               # description text
)

# Regex to extract quota-like numbers from descriptions.
_QUOTA_RE = re.compile(
    r"\b\d[\d,]*(?:\.\d+)?\s*"
    r"(?:MB|GB|TB|KB|"
    r"requests?|reqs?|calls?|"
    r"users?|MAU|DAU|RPM|RPD|TPM|"
    r"projects?|databases?|"
    r"rows?|records?|documents?|"
    r"emails?|messages?|"
    r"builds?|deployments?|"
    r"minutes?|hours?|"
    r"tokens?|credits?|"
    r"images?|assets?|"
    r"GB[/-](?:month|mo|hr|h)|"
    r"(?:/(?:month|mo|day|min|sec|hr)))",
    re.IGNORECASE,
)

MAX_RETRIES = 3


def _resolve_category(header: str) -> ServiceCategory:
    """Map a markdown section header to a ServiceCategory."""
    header_lower = header.lower().strip()
    for key, cat in CATEGORY_MAPPING.items():
        if key in header_lower:
            return cat
    return ServiceCategory.APIS_DEVTOOLS


async def parse_free_for_dev() -> List[ServiceItem]:
    """
    Fetch and parse the free-for-dev README.md from GitHub.

    Returns a list of ServiceItem instances (not yet persisted).
    Retries up to MAX_RETRIES on transient network failures.
    """
    text: str | None = None

    for attempt in range(1, MAX_RETRIES + 1):
        try:
            async with httpx.AsyncClient(follow_redirects=True) as client:
                response = await client.get(MARKDOWN_URL, timeout=30.0)
                response.raise_for_status()
                text = response.text
                break
        except httpx.HTTPStatusError as exc:
            logger.warning(
                "HTTP %s on attempt %d fetching free-for-dev: %s",
                exc.response.status_code, attempt, exc,
            )
        except httpx.RequestError as exc:
            logger.warning(
                "Network error on attempt %d fetching free-for-dev: %s",
                attempt, exc,
            )

    if text is None:
        logger.error("All %d attempts to fetch free-for-dev failed.", MAX_RETRIES)
        return []

    services: list[ServiceItem] = []
    current_category = ServiceCategory.APIS_DEVTOOLS

    for line in text.split("\n"):
        stripped = line.strip()

        # Detect section headers: ## Category Name
        if stripped.startswith("## "):
            header = stripped[3:].strip()
            current_category = _resolve_category(header)
            continue

        # Detect service entries
        match = _ENTRY_RE.match(stripped)
        if match:
            name = match.group(1).strip()
            url = match.group(2).strip()
            description = match.group(3).strip()

            # Truncate short_description to 160 chars
            short_desc = (
                description[:157] + "..." if len(description) > 160 else description
            )

            # Credit-card heuristic
            desc_lower = description.lower()
            requires_cc = (
                "credit card" in desc_lower
                and "no credit card" not in desc_lower
            )

            # Extract quota figures
            limit_matches = _QUOTA_RE.findall(description)
            free_tier_limits = (
                ", ".join(m.strip() for m in limit_matches)
                if limit_matches
                else "See official docs"
            )
            if len(free_tier_limits) > 255:
                free_tier_limits = free_tier_limits[:252] + "..."

            services.append(
                ServiceItem(
                    name=name,
                    category=current_category,
                    short_description=short_desc,
                    free_tier_limits=free_tier_limits,
                    requires_credit_card=requires_cc,
                    has_hard_cap=False,
                    official_url=url,
                    pricing_url=None,
                )
            )

    logger.info("Parsed %d services from free-for-dev.", len(services))
    return services
