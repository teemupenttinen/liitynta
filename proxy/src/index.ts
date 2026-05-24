export interface Env {
  DIGITRANSIT_API_KEY: string;
  APP_TOKEN: string; // set in Worker secrets, checked against X-App-Token header
}

// Upstream base URLs
const UPSTREAM: Record<string, string> = {
  '/routing': 'https://api.digitransit.fi/routing/v2/hsl/gtfs/v1',
  '/geocoding': 'https://api.digitransit.fi/geocoding/v1',
  '/facilities': 'https://parking.fintraffic.fi/api/v1/facilities.json',
  '/utilizations': 'https://parking.fintraffic.fi/api/v1/utilizations.json',
};

// How long to cache each route (seconds). 0 = no cache.
const CACHE_TTL: Record<string, number> = {
  '/routing': 0,       // real-time, never cache
  '/geocoding': 3600,  // addresses are stable
  '/facilities': 300,  // facility list changes rarely
  '/utilizations': 60, // occupancy updates ~1/min
};

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    // Only allow GET and POST
    if (request.method !== 'GET' && request.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 });
    }

    // Validate app token
    if (request.headers.get('X-App-Token') !== env.APP_TOKEN) {
      return new Response('Unauthorized', { status: 401 });
    }

    const url = new URL(request.url);
    const prefix = matchPrefix(url.pathname);

    if (!prefix) {
      return new Response('Not found', { status: 404 });
    }

    const upstreamUrl = buildUpstreamUrl(prefix, url);
    const ttl = CACHE_TTL[prefix];

    // Serve from cache if applicable
    if (ttl > 0 && request.method === 'GET') {
      const cached = await caches.default.match(upstreamUrl);
      if (cached) return cached;
    }

    const upstreamResponse = await fetch(upstreamUrl, {
      method: request.method,
      headers: buildUpstreamHeaders(request, env),
      body: request.method === 'POST' ? request.body : undefined,
    });

    if (!upstreamResponse.ok) {
      return new Response(upstreamResponse.body, {
        status: upstreamResponse.status,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const response = new Response(upstreamResponse.body, {
      status: upstreamResponse.status,
      headers: {
        'Content-Type': upstreamResponse.headers.get('Content-Type') ?? 'application/json',
        'Access-Control-Allow-Origin': '*',
        ...(ttl > 0 ? { 'Cache-Control': `public, max-age=${ttl}` } : {}),
      },
    });

    // Store in cache
    if (ttl > 0 && request.method === 'GET') {
      await caches.default.put(upstreamUrl, response.clone());
    }

    return response;
  },
};

function matchPrefix(pathname: string): string | null {
  for (const prefix of Object.keys(UPSTREAM)) {
    if (pathname === prefix || pathname.startsWith(prefix + '/') || pathname.startsWith(prefix + '?')) {
      return prefix;
    }
  }
  return null;
}

function buildUpstreamUrl(prefix: string, url: URL): string {
  const upstream = UPSTREAM[prefix];

  if (prefix === '/routing') {
    // GraphQL endpoint — no path suffix or query params, just POST to the base URL
    return upstream;
  }

  if (prefix === '/geocoding') {
    // Forward full path — /geocoding/v1/autocomplete → https://api.digitransit.fi/geocoding/v1/autocomplete
    return `https://api.digitransit.fi${url.pathname}${url.search}`;
  }

  // /facilities and /utilizations map directly to their fixed URLs with original query params
  return `${upstream}${url.search}`;
}

function buildUpstreamHeaders(request: Request, env: Env): Headers {
  const headers = new Headers();
  headers.set('digitransit-subscription-key', env.DIGITRANSIT_API_KEY);

  // Forward Content-Type for POST (GraphQL)
  const ct = request.headers.get('Content-Type');
  if (ct) headers.set('Content-Type', ct);

  return headers;
}
