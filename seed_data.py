import logging
from sqlmodel import Session, select
from database import engine, create_db_and_tables
from models import ServiceItem, ServiceCategory, ServiceStatus

def seed_db():
    create_db_and_tables()
    with Session(engine) as session:
        existing = session.exec(select(ServiceItem)).first()
        if existing:
            print("DB already seeded.")
            return

        services = [
            # Original items
            ServiceItem(
                name="Groq Cloud", category=ServiceCategory.AI_ML, short_description="Fastest AI inference platform offering APIs for Llama and Mixtral models.",
                free_tier_limits="14,400 requests/day, 30 requests/minute", requires_credit_card=False, official_url="https://console.groq.com/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Google Gemini API", category=ServiceCategory.AI_ML, short_description="Access to Google's most capable AI models.",
                free_tier_limits="15 RPM, 1M TPM, 1,500 RPD", requires_credit_card=False, official_url="https://ai.google.dev/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Hugging Face Inference", category=ServiceCategory.AI_ML, short_description="Free tier for experimenting with thousands of models.",
                free_tier_limits="30k tokens/min", requires_credit_card=False, official_url="https://huggingface.co/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Cohere", category=ServiceCategory.AI_ML, short_description="NLP models and embedding APIs.",
                free_tier_limits="1000 calls/month for Trial keys", requires_credit_card=False, official_url="https://cohere.com/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Mistral", category=ServiceCategory.AI_ML, short_description="Open and optimized AI models.",
                free_tier_limits="Rate limits apply to free tier, no guaranteed uptime", requires_credit_card=True, official_url="https://mistral.ai/", status=ServiceStatus.CHANGED_RECENTLY, change_log_summary="Added credit card requirement for free tier access."
            ),
            ServiceItem(
                name="Supabase", category=ServiceCategory.DATABASES, short_description="Open source Firebase alternative with Postgres database.",
                free_tier_limits="500MB DB space, 1GB file storage, 50k MAU auth", requires_credit_card=False, official_url="https://supabase.com/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Neon", category=ServiceCategory.DATABASES, short_description="Serverless Postgres database.",
                free_tier_limits="500MB storage, 1 project, shared compute", requires_credit_card=False, official_url="https://neon.tech/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Turso", category=ServiceCategory.DATABASES, short_description="Edge database based on libSQL (SQLite fork).",
                free_tier_limits="9GB total storage, 1 billion row reads/month", requires_credit_card=False, official_url="https://turso.tech/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="PlanetScale", category=ServiceCategory.DATABASES, short_description="Serverless MySQL platform. Free tier deprecated.",
                free_tier_limits="None (Hobby tier removed)", requires_credit_card=True, official_url="https://planetscale.com/", status=ServiceStatus.DEPRECATED, change_log_summary="Hobby tier was discontinued in April 2024."
            ),
            ServiceItem(
                name="MongoDB Atlas", category=ServiceCategory.DATABASES, short_description="Managed MongoDB database.",
                free_tier_limits="512MB storage, shared RAM", requires_credit_card=False, official_url="https://www.mongodb.com/atlas", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="CockroachDB", category=ServiceCategory.DATABASES, short_description="Distributed SQL database.",
                free_tier_limits="Serverless free up to 10GB storage, 50M RUs/month", requires_credit_card=True, official_url="https://www.cockroachlabs.com/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Vercel", category=ServiceCategory.HOSTING_PAAS, short_description="Frontend framework hosting and Serverless Functions.",
                free_tier_limits="100GB bandwidth, 100M function executions", requires_credit_card=False, official_url="https://vercel.com/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Cloudflare Pages/Workers", category=ServiceCategory.HOSTING_PAAS, short_description="Edge computing and static hosting.",
                free_tier_limits="100k requests/day (Workers), 500 builds/month (Pages)", requires_credit_card=False, official_url="https://workers.cloudflare.com/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Railway", category=ServiceCategory.HOSTING_PAAS, short_description="Infrastructure platform where you can provision infrastructure, entangle it with variables, and deploy it to a custom domain.",
                free_tier_limits="$5 credit, needs verified account (CC or GH)", requires_credit_card=True, official_url="https://railway.app/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Render", category=ServiceCategory.HOSTING_PAAS, short_description="Unified cloud to build and run all your apps and websites.",
                free_tier_limits="Free static sites, 750 free hours/month for Web Services/DBs (spins down)", requires_credit_card=False, official_url="https://render.com/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Fly.io", category=ServiceCategory.HOSTING_PAAS, short_description="Run your full stack apps (and databases!) all over the world.",
                free_tier_limits="Up to 3 shared-cpu-1x 256mb VMs, 3GB persistent volume", requires_credit_card=True, official_url="https://fly.io/", status=ServiceStatus.CHANGED_RECENTLY, change_log_summary="Card requirement heavily enforced, trial credits replaced free tier for some."
            ),
            ServiceItem(
                name="Clerk", category=ServiceCategory.AUTH_SECURITY, short_description="More than just authentication. Complete user management.",
                free_tier_limits="10,000 Monthly Active Users", requires_credit_card=False, official_url="https://clerk.com/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Auth0", category=ServiceCategory.AUTH_SECURITY, short_description="Secure access for everyone. But not just anyone.",
                free_tier_limits="7,500 Active Users, unlimited logins", requires_credit_card=False, official_url="https://auth0.com/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Firebase Auth", category=ServiceCategory.AUTH_SECURITY, short_description="Authenticate and manage users from a variety of providers.",
                free_tier_limits="50,000 MAUs for Phone, unlimited email/social", requires_credit_card=False, official_url="https://firebase.google.com/products/auth", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Cloudflare R2", category=ServiceCategory.STORAGE_CDN, short_description="S3-compatible object storage with zero egress fees.",
                free_tier_limits="10GB storage, 1M Class A ops/mo, 10M Class B ops/mo", requires_credit_card=True, official_url="https://www.cloudflare.com/products/r2/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Backblaze B2", category=ServiceCategory.STORAGE_CDN, short_description="Cloud Object Storage.",
                free_tier_limits="10GB storage free, 1GB daily download free", requires_credit_card=False, official_url="https://www.backblaze.com/b2/cloud-storage.html", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Uploadthing", category=ServiceCategory.STORAGE_CDN, short_description="File uploads for modern web devs.",
                free_tier_limits="2GB storage, 2GB bandwidth", requires_credit_card=False, official_url="https://uploadthing.com/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="GitHub Actions", category=ServiceCategory.APIS_DEVTOOLS, short_description="Automate your workflow from idea to production.",
                free_tier_limits="2,000 CI/CD minutes/month for free accounts", requires_credit_card=False, official_url="https://github.com/features/actions", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Postmark", category=ServiceCategory.APIS_DEVTOOLS, short_description="Fast and reliable email delivery.",
                free_tier_limits="100 emails/month", requires_credit_card=False, official_url="https://postmarkapp.com/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Resend", category=ServiceCategory.APIS_DEVTOOLS, short_description="Email for developers.",
                free_tier_limits="3,000 emails/month (100/day), 1 custom domain", requires_credit_card=False, official_url="https://resend.com/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Sentry", category=ServiceCategory.APIS_DEVTOOLS, short_description="Application performance monitoring & error tracking.",
                free_tier_limits="5K errors/month, 10K transactions/mo", requires_credit_card=False, official_url="https://sentry.io/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Unsplash", category=ServiceCategory.CREATIVE_ASSETS, short_description="Beautiful, free images and photos.",
                free_tier_limits="Unlimited usage under Unsplash license", requires_credit_card=False, official_url="https://unsplash.com/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Google Fonts", category=ServiceCategory.CREATIVE_ASSETS, short_description="Library of free licensed font families and APIs.",
                free_tier_limits="Unlimited", requires_credit_card=False, official_url="https://fonts.google.com/", status=ServiceStatus.ACTIVE
            ),
            
            # --- AI_ML ---
            ServiceItem(
                name="OpenRouter", category=ServiceCategory.AI_ML, short_description="Unified AI API with free models.",
                free_tier_limits="Various free models with generous limits", requires_credit_card=False, official_url="https://openrouter.ai/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Together AI", category=ServiceCategory.AI_ML, short_description="Fast cloud platform for building and running generative AI.",
                free_tier_limits="Free trial tokens upon signup ($5)", requires_credit_card=False, official_url="https://www.together.ai/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Replicate", category=ServiceCategory.AI_ML, short_description="Run AI with an API.",
                free_tier_limits="Free predictions available to test models", requires_credit_card=False, official_url="https://replicate.com/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Anthropic Claude", category=ServiceCategory.AI_ML, short_description="AI assistant built for safety and performance.",
                free_tier_limits="Limited free usage via API playground", requires_credit_card=False, official_url="https://www.anthropic.com/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="OpenAI", category=ServiceCategory.AI_ML, short_description="API for GPT models.",
                free_tier_limits="$5 credit for new accounts, requires CC to prevent abuse", requires_credit_card=True, official_url="https://openai.com/", status=ServiceStatus.CHANGED_RECENTLY, change_log_summary="Updated verification process requiring phone or CC for free trial."
            ),

            # --- DATABASES ---
            ServiceItem(
                name="Firebase Realtime DB", category=ServiceCategory.DATABASES, short_description="Cloud-hosted NoSQL database.",
                free_tier_limits="1GB stored, 10GB/month download", requires_credit_card=False, official_url="https://firebase.google.com/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Upstash Redis", category=ServiceCategory.DATABASES, short_description="Serverless Redis for developers.",
                free_tier_limits="10K commands/day, 256MB max size", requires_credit_card=False, official_url="https://upstash.com/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Xata", category=ServiceCategory.DATABASES, short_description="Serverless database based on PostgreSQL.",
                free_tier_limits="Free 15GB, 750 requests/sec", requires_credit_card=False, official_url="https://xata.io/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="D1 Cloudflare", category=ServiceCategory.DATABASES, short_description="Serverless SQL database native to Cloudflare.",
                free_tier_limits="5GB storage, 5M rows read/day", requires_credit_card=False, official_url="https://developers.cloudflare.com/d1/", status=ServiceStatus.ACTIVE
            ),

            # --- HOSTING_PAAS ---
            ServiceItem(
                name="Netlify", category=ServiceCategory.HOSTING_PAAS, short_description="Platform for building highly-performant static sites.",
                free_tier_limits="100GB bandwidth, 300 build minutes", requires_credit_card=False, official_url="https://www.netlify.com/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="GitHub Pages", category=ServiceCategory.HOSTING_PAAS, short_description="Websites for you and your projects.",
                free_tier_limits="1GB storage, public repos, 100GB bandwidth", requires_credit_card=False, official_url="https://pages.github.com/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Deno Deploy", category=ServiceCategory.HOSTING_PAAS, short_description="Serverless JavaScript infrastructure.",
                free_tier_limits="1M requests/month, 100K KV reads/day", requires_credit_card=False, official_url="https://deno.com/deploy", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Zeabur", category=ServiceCategory.HOSTING_PAAS, short_description="Deploy full stack apps easily.",
                free_tier_limits="Free hobby plan, resource limited", requires_credit_card=False, official_url="https://zeabur.com/", status=ServiceStatus.ACTIVE
            ),

            # --- AUTH_SECURITY ---
            ServiceItem(
                name="Hanko", category=ServiceCategory.AUTH_SECURITY, short_description="Passkey-first authentication.",
                free_tier_limits="10K users", requires_credit_card=False, official_url="https://www.hanko.io/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Kinde", category=ServiceCategory.AUTH_SECURITY, short_description="Simple, powerful auth.",
                free_tier_limits="10.5K MAU", requires_credit_card=False, official_url="https://kinde.com/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Logto", category=ServiceCategory.AUTH_SECURITY, short_description="Identity infrastructure for developers.",
                free_tier_limits="50K MAU, open source", requires_credit_card=False, official_url="https://logto.io/", status=ServiceStatus.ACTIVE
            ),

            # --- STORAGE_CDN ---
            ServiceItem(
                name="Cloudinary", category=ServiceCategory.STORAGE_CDN, short_description="Image and video management.",
                free_tier_limits="25 credits/month (~25GB bandwidth/storage)", requires_credit_card=False, official_url="https://cloudinary.com/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="ImageKit", category=ServiceCategory.STORAGE_CDN, short_description="Image optimization and delivery.",
                free_tier_limits="20GB bandwidth/month", requires_credit_card=False, official_url="https://imagekit.io/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Bunny CDN", category=ServiceCategory.STORAGE_CDN, short_description="Fast, reliable CDN.",
                free_tier_limits="14-day trial, then paid", requires_credit_card=False, official_url="https://bunny.net/", status=ServiceStatus.DEPRECATED, change_log_summary="Trial model only, no permanent free tier anymore."
            ),

            # --- APIS_DEVTOOLS ---
            ServiceItem(
                name="Vercel KV / Blob", category=ServiceCategory.APIS_DEVTOOLS, short_description="Serverless storage for Vercel apps.",
                free_tier_limits="Included in Vercel free tier limits", requires_credit_card=False, official_url="https://vercel.com/docs/storage", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Axiom", category=ServiceCategory.APIS_DEVTOOLS, short_description="Logging and analytics.",
                free_tier_limits="500GB ingest/month", requires_credit_card=False, official_url="https://axiom.co/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Betterstack", category=ServiceCategory.APIS_DEVTOOLS, short_description="Monitoring and logging.",
                free_tier_limits="Logtail 1GB/month", requires_credit_card=False, official_url="https://betterstack.com/", status=ServiceStatus.CHANGED_RECENTLY, change_log_summary="Updated free tier limits for Logtail product."
            ),
            ServiceItem(
                name="Deno KV", category=ServiceCategory.APIS_DEVTOOLS, short_description="Global key-value database.",
                free_tier_limits="Built into Deno Deploy free limits", requires_credit_card=False, official_url="https://deno.com/kv", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Val Town", category=ServiceCategory.APIS_DEVTOOLS, short_description="Social website to write and deploy code.",
                free_tier_limits="Free 10MB storage, 1K runs/day", requires_credit_card=False, official_url="https://www.val.town/", status=ServiceStatus.ACTIVE
            ),

            # --- CREATIVE_ASSETS ---
            ServiceItem(
                name="Pexels", category=ServiceCategory.CREATIVE_ASSETS, short_description="Free stock photos and videos.",
                free_tier_limits="Unlimited free photos/videos", requires_credit_card=False, official_url="https://www.pexels.com/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Iconify", category=ServiceCategory.CREATIVE_ASSETS, short_description="Unified icon framework.",
                free_tier_limits="Open source icon sets", requires_credit_card=False, official_url="https://iconify.design/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Lucide Icons", category=ServiceCategory.CREATIVE_ASSETS, short_description="Beautiful & consistent icon toolkit.",
                free_tier_limits="Open source", requires_credit_card=False, official_url="https://lucide.dev/", status=ServiceStatus.ACTIVE
            ),
            ServiceItem(
                name="Coolors", category=ServiceCategory.CREATIVE_ASSETS, short_description="Color palettes generator.",
                free_tier_limits="Free for basic usage", requires_credit_card=False, official_url="https://coolors.co/", status=ServiceStatus.ACTIVE
            ),
        ]
        
        for s in services:
            session.add(s)
        session.commit()
        print(f"Seeded {len(services)} services.")

if __name__ == "__main__":
    seed_db()
