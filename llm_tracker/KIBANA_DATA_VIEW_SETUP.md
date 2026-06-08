# 📊 Kibana Data View Setup Guide

## Current Status

✅ **Elasticsearch Index Created**: `llm-value-scores`
- Documents: 674
- Status: Green/Yellow (1 node)
- Ready for visualization

## Step-by-Step: Create Data View in Kibana

### Method 1: Using Kibana UI (Recommended) 🎯

#### Step 1: Access Kibana
1. Open browser: **http://localhost:5601**
2. Kibana opens automatically (all plugins loaded)

#### Step 2: Navigate to Data Views
1. Click menu icon (☰) in top left
2. Go to **Stack Management**
3. Select **Data Views** (left sidebar)

#### Step 3: Create New Data View
1. Click **+ Create data view** button (top right)
2. Fill in the form:

   **Index pattern**: `llm-value-scores*`
   - This matches all indices starting with "llm-value-scores"
   
   **Timestamp field**: `ingestion_date`
   - Enables time-based filtering
   - Used for time-series visualizations
   
   **Name** (Optional): `LLM Value Scores`
   - User-friendly display name

3. Click **Save data view** button

#### Step 4: Verify Data View
1. You should see:
   - "LLM Value Scores" data view created
   - Displays available fields from your data
   - Shows field types (keyword, float, date, etc.)

### Method 2: Using Kibana API 💻

#### Create Data View via cURL

```bash
# From your terminal (not in Docker)
curl -X POST http://localhost:5601/api/data_views/data_views \
  -H "kbn-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "data_view": {
      "title": "llm-value-scores*",
      "timeFieldName": "ingestion_date",
      "name": "LLM Value Scores"
    }
  }'
```

#### Expected Response
```json
{
  "data_view": {
    "id": "some-id-here",
    "version": "...",
    "title": "llm-value-scores*",
    "name": "LLM Value Scores",
    "timeFieldName": "ingestion_date",
    "fields": [...]
  }
}
```

---

## 📋 Data View Details

### Index Pattern: `llm-value-scores*`

Matches all indices:
- `llm-value-scores`
- `llm-value-scores-2024-06`
- Any future indices following this pattern

### Time Field: `ingestion_date`

Properties:
- Type: `date`
- Usage: Time-based filtering and visualization
- Allows date histogram aggregations

### Available Fields in Data

```
ingestion_date ........... date (Timestamp)
model_id ................. keyword (Model identifier)
model_name ............... keyword (LLM name)
provider ................. keyword (e.g., OpenAI, Anthropic)
performance_score ........ float (0-100)
avg_price_per_1m_usd .... float (Cost in USD)
value_score .............. float (Performance/Cost ratio)
context_window ........... integer (Context length)
```

---

## 🎨 What You Can Do After Creating Data View

### 1. Create Visualizations
- **Line Chart**: Performance over time
- **Bar Chart**: Compare models by cost
- **Scatter Plot**: Performance vs Cost
- **Table**: Browse raw data

### 2. Build Dashboards
Combine multiple visualizations:
- Model rankings by value
- Cost comparison
- Performance trends
- Provider breakdown

### 3. Search & Filter
- Filter by provider (OpenAI, Anthropic, Meta, etc.)
- Filter by date range
- Search by model name
- Compare specific models

### 4. Export Data
- Download as CSV
- Export visualizations
- Share dashboards

---

## ✅ Quick Checklist

After creating the data view, verify:

- [ ] Data view appears in Stack Management → Data Views
- [ ] Fields are populated (showing available columns)
- [ ] Time field is set to "ingestion_date"
- [ ] Can see 674 documents from Elasticsearch
- [ ] No errors in Kibana UI

---

## 🐛 Troubleshooting

### Issue: "Index not found"
**Solution**: Verify index exists
```bash
# Check Elasticsearch indices
curl http://localhost:9200/_cat/indices?v

# Should show: llm-value-scores with 674 docs
```

### Issue: "No time field"
**Solution**: Make sure `ingestion_date` exists
```bash
# Check index mapping
curl http://localhost:9200/llm-value-scores/_mapping
```

### Issue: Data view not appearing
**Solution**: Clear Kibana cache
1. Press Ctrl+Shift+Delete (or Cmd+Shift+Delete on Mac)
2. Clear "Cookies and other site data"
3. Reload page

### Issue: Can't create data view via API
**Solution**: Check Kibana is ready
```bash
# Test Kibana API
curl http://localhost:5601/api/status

# Should return status object
```

---

## 📊 Example Queries After Setup

### Find High-Value Models
```
Query: value_score > 1.0
Sort: value_score DESC
```

### Compare Providers
```
Aggregation: Breakdown by provider
Metric: Average performance_score
```

### Cost Analysis
```
Query: Date range = Last 7 days
Aggregation: Breakdown by model_name
Metric: Average avg_price_per_1m_usd
```

---

## 🎯 Next Steps

1. **Create Data View** (using instructions above)
2. **Create Visualization** 
   - Go to **Visualize**
   - Select **LLM Value Scores** data view
   - Choose visualization type
3. **Build Dashboard**
   - Go to **Dashboards**
   - Create new dashboard
   - Add visualizations

---

## 📚 Related Documentation

- [Kibana Data Views](https://www.elastic.co/guide/en/kibana/current/data-views.html)
- [Creating Visualizations](https://www.elastic.co/guide/en/kibana/current/visualizations.html)
- [Kibana Dashboards](https://www.elastic.co/guide/en/kibana/current/dashboard.html)

---

## ✨ You're All Set!

Your Elasticsearch data is ready to explore in Kibana:

✅ Index: **llm-value-scores** (674 documents)
✅ Time field: **ingestion_date**
✅ Status: Ready for visualization

**Create your data view and start analyzing! 🚀**

---

## 📞 Need Help?

### Quick Start (Next 5 minutes)
1. Open http://localhost:5601
2. Follow Method 1 steps above
3. Create data view with default settings

### Creating Visualizations (Next 15 minutes)
1. Click Visualize
2. Select LLM Value Scores
3. Choose chart type
4. Set axes and aggregations

### Full Dashboard (Next 30 minutes)
1. Create multiple visualizations
2. Add to dashboard
3. Set filters and time ranges
4. Share dashboard

---

**Happy analyzing! 📊**
