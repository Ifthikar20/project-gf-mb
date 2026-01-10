# Backend API Changes for Search Feature

## Overview

This document describes the required backend API changes to support the mobile app's search feature with tag filtering.

---

## Endpoint: `GET /content/browse`

### Current Behavior
Returns content list from the `content` array in response.

### Required Changes

Add support for the following query parameters:

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `search` | string | Search query (max 100 chars) | `?search=meditation` |
| `content_type` | string | Filter by type: `video`, `audio`, `podcast` | `?content_type=video` |
| `category` | string | Filter by category slug (lowercase) | `?category=sleep` |
| `tags` | string | **NEW**: Comma-separated list of tags | `?tags=anxiety,stress,sleep` |

### Example Request
```
GET /content/browse?search=wellness&content_type=video&category=sleep&tags=anxiety,stress
```

### Expected Response Format
```json
{
  "content": [
    {
      "id": "uuid",
      "title": "Content Title",
      "description": "Description text",
      "content_type": "video|audio|podcast",
      "thumbnail_url": "https://...",
      "duration_seconds": 600,
      "expert_name": "Dr. Example",
      "category_name": "Sleep",
      "tags": ["anxiety", "stress", "beginner"]
    }
  ]
}
```

---

## Tag Filtering Implementation

### Option 1: Database Query (Recommended)
```python
# SQLAlchemy example
if tags:
    tag_list = [t.strip().lower() for t in tags.split(',')]
    query = query.filter(Content.tags.overlap(tag_list))
```

### Option 2: PostgreSQL Array Overlap
```sql
SELECT * FROM content 
WHERE tags && ARRAY['anxiety', 'stress']::text[]
```

### Option 3: Many-to-Many Relationship
```sql
SELECT DISTINCT c.* FROM content c
JOIN content_tags ct ON c.id = ct.content_id
JOIN tags t ON ct.tag_id = t.id
WHERE t.name IN ('anxiety', 'stress')
```

---

## Security Considerations

The mobile app implements these security measures:

| Protection | Implementation |
|------------|----------------|
| **Query length limit** | Max 100 characters |
| **SQL injection** | Pattern detection + sanitization |
| **XSS prevention** | Script tag detection |
| **Tag limits** | Max 10 tags, 50 chars each |
| **Whitelist validation** | Content type + category validation |

### Backend Security Recommendations

1. **Validate all inputs** server-side regardless of client sanitization
2. **Use parameterized queries** to prevent SQL injection
3. **Rate limit** search endpoint (suggest: 30 req/min per user)
4. **Log suspicious patterns** for security monitoring

---

## Content Tags Schema

### Add Tags to Content Table
```sql
ALTER TABLE content 
ADD COLUMN tags TEXT[] DEFAULT '{}';

-- Or create a separate tags table for normalization
CREATE TABLE tags (
    id UUID PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE content_tags (
    content_id UUID REFERENCES content(id),
    tag_id UUID REFERENCES tags(id),
    PRIMARY KEY (content_id, tag_id)
);
```

### Suggested Tag Categories
- **Mood**: anxiety, stress, calm, peaceful, energizing
- **Time**: morning, evening, quick, extended
- **Difficulty**: beginner, intermediate, advanced
- **Topic**: sleep, focus, meditation, breathing, mindfulness

---

## Testing

### cURL Examples
```bash
# Search with tags
curl -X GET "http://api.example.com/content/browse?search=meditation&tags=anxiety,stress" \
  -H "Authorization: Bearer TOKEN"

# Filter by content type and tags
curl -X GET "http://api.example.com/content/browse?content_type=audio&tags=sleep,beginner" \
  -H "Authorization: Bearer TOKEN"
```

---

## Migration Checklist

- [ ] Add `tags` column to content table (or create junction table)
- [ ] Update `/content/browse` endpoint to accept `tags` parameter
- [ ] Implement tag filtering in database query
- [ ] Add input validation for tags parameter
- [ ] Update API documentation
- [ ] Tag existing content in database
- [ ] Test with mobile app
