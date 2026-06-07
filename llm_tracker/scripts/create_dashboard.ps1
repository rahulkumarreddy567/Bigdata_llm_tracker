# ─────────────────────────────────────────────────────────────────────────────
# create_dashboard.ps1
# Creates a Kibana 8.12 Data View + Dashboard with inline Lens panels
# using the Saved Objects API.
# ─────────────────────────────────────────────────────────────────────────────

$baseUrl  = "http://localhost:5601"
$headers  = @{ "kbn-xsrf" = "true"; "Content-Type" = "application/json" }
$indexName = "llm_value_scores"
$dataViewId = "llm-data-view"
$dashboardId = "llm-dashboard-main"

# ── 1. Create Data View ────────────────────────────────────────────────────
Write-Host "[1/2] Creating Data View '$indexName'..."
$dvBody = @{
    data_view = @{
        title = $indexName
        id    = $dataViewId
        timeFieldName = "ingestion_date"
    }
    override = $true
} | ConvertTo-Json -Depth 5

try {
    Invoke-RestMethod -Uri "$baseUrl/api/data_views/data_view" -Method Post -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($dvBody)) -ContentType "application/json; charset=utf-8"
    Write-Host "[OK] Data View created."
} catch {
    Write-Host "[WARN] Data View may already exist: $($_.Exception.Message)"
}

# ── 2. Build Dashboard with inline Lens panels ────────────────────────────
Write-Host "[2/2] Creating Dashboard with Lens panels..."

# Helper: builds a Lens metric panel config
function New-LensMetric {
    param([string]$Title, [string]$DataViewId, [string]$AggType, [string]$FieldName, [string]$Query)
    
    $accessor = if ($AggType -eq "count") { "count" } else { "${AggType}_${FieldName}" }
    $colId = "col-$accessor"
    
    $columns = @{}
    if ($AggType -eq "count") {
        $columns[$colId] = @{
            label = $Title
            dataType = "number"
            isBucketed = $false
            operationType = "count"
            scale = "ratio"
            sourceField = "___records___"
        }
    } else {
        $columns[$colId] = @{
            label = $Title
            dataType = "number"
            isBucketed = $false
            operationType = $AggType
            scale = "ratio"
            sourceField = $FieldName
        }
    }
    
    return @{
        title = $Title
        description = ""
        visualizationType = "lnsMetric"
        state = @{
            visualization = @{
                layerId = "layer1"
                layerType = "data"
                metricAccessor = $colId
            }
            query = @{ query = $Query; language = "kuery" }
            filters = @()
            datasourceStates = @{
                formBased = @{
                    layers = @{
                        layer1 = @{
                            columns = $columns
                            columnOrder = @($colId)
                            incompleteColumns = @{}
                        }
                    }
                }
            }
        }
        references = @(
            @{
                type = "index-pattern"
                id = $DataViewId
                name = "indexpattern-datasource-layer-layer1"
            }
        )
    }
}

# Helper: builds a Lens bar chart panel config  
function New-LensBar {
    param([string]$Title, [string]$DataViewId, [string]$MetricAgg, [string]$MetricField, 
          [string]$BucketField, [int]$BucketSize, [string]$Query, [bool]$Horizontal)
    
    $metricColId = if ($MetricAgg -eq "count") { "metric-count" } else { "metric-$MetricField" }
    $bucketColId = "bucket-$BucketField"
    
    $metricCol = @{}
    if ($MetricAgg -eq "count") {
        $metricCol = @{
            label = "Count"
            dataType = "number"
            isBucketed = $false
            operationType = "count"
            scale = "ratio"
            sourceField = "___records___"
        }
    } else {
        $metricCol = @{
            label = "$MetricAgg of $MetricField"
            dataType = "number"
            isBucketed = $false
            operationType = $MetricAgg
            scale = "ratio"
            sourceField = $MetricField
        }
    }
    
    $bucketCol = @{
        label = $BucketField
        dataType = "string"
        isBucketed = $true
        operationType = "terms"
        scale = "ordinal"
        sourceField = $BucketField
        params = @{
            size = $BucketSize
            orderBy = @{ type = "column"; columnId = $metricColId }
            orderDirection = "desc"
        }
    }
    
    $vizConfig = @{
        preferredSeriesType = if ($Horizontal) { "bar_horizontal" } else { "bar" }
        layers = @(
            @{
                layerId = "layer1"
                layerType = "data"
                seriesType = if ($Horizontal) { "bar_horizontal" } else { "bar" }
                xAccessor = $bucketColId
                accessors = @($metricColId)
            }
        )
        legend = @{ isVisible = $false }
        valueLabels = "show"
    }
    
    return @{
        title = $Title
        description = ""
        visualizationType = "lnsXY"
        state = @{
            visualization = $vizConfig
            query = @{ query = $Query; language = "kuery" }
            filters = @()
            datasourceStates = @{
                formBased = @{
                    layers = @{
                        layer1 = @{
                            columns = @{
                                $metricColId = $metricCol
                                $bucketColId = $bucketCol
                            }
                            columnOrder = @($bucketColId, $metricColId)
                            incompleteColumns = @{}
                        }
                    }
                }
            }
        }
        references = @(
            @{
                type = "index-pattern"
                id = $DataViewId
                name = "indexpattern-datasource-layer-layer1"
            }
        )
    }
}

# Helper: builds a Lens pie/donut chart panel config
function New-LensPie {
    param([string]$Title, [string]$DataViewId, [string]$BucketField, [int]$BucketSize, [string]$Query, [bool]$IsDonut)
    
    $metricColId = "metric-count"
    $bucketColId = "bucket-$BucketField"
    
    return @{
        title = $Title
        description = ""
        visualizationType = "lnsPie"
        state = @{
            visualization = @{
                shape = if ($IsDonut) { "donut" } else { "pie" }
                layers = @(
                    @{
                        layerId = "layer1"
                        layerType = "data"
                        primaryGroups = @($bucketColId)
                        metrics = @($metricColId)
                        numberDisplay = "percent"
                        categoryDisplay = "default"
                        legendDisplay = "default"
                    }
                )
            }
            query = @{ query = $Query; language = "kuery" }
            filters = @()
            datasourceStates = @{
                formBased = @{
                    layers = @{
                        layer1 = @{
                            columns = @{
                                $metricColId = @{
                                    label = "Count"
                                    dataType = "number"
                                    isBucketed = $false
                                    operationType = "count"
                                    scale = "ratio"
                                    sourceField = "___records___"
                                }
                                $bucketColId = @{
                                    label = $BucketField
                                    dataType = "string"
                                    isBucketed = $true
                                    operationType = "terms"
                                    scale = "ordinal"
                                    sourceField = $BucketField
                                    params = @{
                                        size = $BucketSize
                                        orderBy = @{ type = "column"; columnId = $metricColId }
                                        orderDirection = "desc"
                                    }
                                }
                            }
                            columnOrder = @($bucketColId, $metricColId)
                            incompleteColumns = @{}
                        }
                    }
                }
            }
        }
        references = @(
            @{
                type = "index-pattern"
                id = $DataViewId
                name = "indexpattern-datasource-layer-layer1"
            }
        )
    }
}

# ── Build all panel definitions ────────────────────────────────────────────

$p1_attrs = New-LensMetric -Title "Total Models" -DataViewId $dataViewId -AggType "count" -FieldName "" -Query ""
$p2_attrs = New-LensMetric -Title "Ranked Models" -DataViewId $dataViewId -AggType "count" -FieldName "" -Query "has_quality_data: true"
$p3_attrs = New-LensMetric -Title "Avg USD/1M tokens" -DataViewId $dataViewId -AggType "average" -FieldName "avg_price_per_1m_usd" -Query "avg_price_per_1m_usd > 0"

$p4_attrs = New-LensBar -Title "Top 10 Best Value LLMs" -DataViewId $dataViewId -MetricAgg "max" -MetricField "value_score" -BucketField "model_name" -BucketSize 10 -Query "has_quality_data: true AND avg_price_per_1m_usd > 0" -Horizontal $true
$p5_attrs = New-LensBar -Title "Models by Provider (Top 15)" -DataViewId $dataViewId -MetricAgg "count" -MetricField "" -BucketField "provider" -BucketSize 15 -Query "" -Horizontal $true

$p6_attrs = New-LensPie -Title "Price Tier Distribution" -DataViewId $dataViewId -BucketField "price_tier" -BucketSize 5 -Query "" -IsDonut $true
$p7_attrs = New-LensPie -Title "Quality Tier Distribution" -DataViewId $dataViewId -BucketField "quality_tier" -BucketSize 5 -Query "" -IsDonut $true

$p8_attrs = New-LensBar -Title "Top Providers by Avg Value Score" -DataViewId $dataViewId -MetricAgg "average" -MetricField "value_score" -BucketField "provider" -BucketSize 10 -Query "has_quality_data: true AND avg_price_per_1m_usd > 0" -Horizontal $false

# ── Build panels JSON array ────────────────────────────────────────────────
$panels = @()

function Add-Panel {
    param($Panels, [string]$Id, [int]$X, [int]$Y, [int]$W, [int]$H, $Attrs)
    
    $panel = @{
        version = "8.12.0"
        type = "lens"
        gridData = @{ x = $X; y = $Y; w = $W; h = $H; i = $Id }
        panelIndex = $Id
        embeddableConfig = @{
            attributes = $Attrs
            enhancements = @{}
        }
    }
    return $panel
}

$panels += Add-Panel -Id "p1" -X 0  -Y 0  -W 16 -H 8  -Attrs $p1_attrs
$panels += Add-Panel -Id "p2" -X 16 -Y 0  -W 16 -H 8  -Attrs $p2_attrs
$panels += Add-Panel -Id "p3" -X 32 -Y 0  -W 16 -H 8  -Attrs $p3_attrs
$panels += Add-Panel -Id "p4" -X 0  -Y 8  -W 24 -H 16 -Attrs $p4_attrs
$panels += Add-Panel -Id "p5" -X 24 -Y 8  -W 24 -H 16 -Attrs $p5_attrs
$panels += Add-Panel -Id "p6" -X 0  -Y 24 -W 24 -H 14 -Attrs $p6_attrs
$panels += Add-Panel -Id "p7" -X 24 -Y 24 -W 24 -H 14 -Attrs $p7_attrs
$panels += Add-Panel -Id "p8" -X 0  -Y 38 -W 48 -H 16 -Attrs $p8_attrs

$panelsJson = $panels | ConvertTo-Json -Depth 20 -Compress

# ── Create Dashboard saved object ─────────────────────────────────────────
$dashBody = @{
    attributes = @{
        title = "LLM Cost vs Performance Dashboard"
        description = "Daily tracker: which LLM gives the best quality per euro spent? Combines OpenRouter pricing with LMSYS Chatbot Arena quality rankings."
        hits = 0
        timeRestore = $true
        timeTo = "now"
        timeFrom = "now-5y"
        refreshInterval = @{ pause = $true; value = 0 }
        panelsJSON = $panelsJson
        optionsJSON = '{"useMargins":true,"syncColors":false,"syncCursor":true,"syncTooltips":false,"hidePanelTitles":false}'
        version = 1
        kibanaSavedObjectMeta = @{
            searchSourceJSON = '{"query":{"query":"","language":"kuery"},"filter":[]}'
        }
    }
    references = @()
} | ConvertTo-Json -Depth 25 -Compress

try {
    $resp = Invoke-RestMethod -Uri "$baseUrl/api/saved_objects/dashboard/$dashboardId`?overwrite=true" -Method Post -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($dashBody)) -ContentType "application/json; charset=utf-8"
    Write-Host "[OK] Dashboard created: $dashboardId"
} catch {
    # Try PUT update if POST fails
    try {
        $updateBody = @{
            attributes = ($dashBody | ConvertFrom-Json).attributes
        } | ConvertTo-Json -Depth 25 -Compress
        Invoke-RestMethod -Uri "$baseUrl/api/saved_objects/dashboard/$dashboardId" -Method Put -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($updateBody)) -ContentType "application/json; charset=utf-8"
        Write-Host "[OK] Dashboard updated: $dashboardId"
    } catch {
        Write-Host "[FAIL] Dashboard create/update failed: $($_.Exception.Message)"
        Write-Host "       $($_.ErrorDetails.Message)"
    }
}

Write-Host ""
Write-Host "Done! Open: $baseUrl/app/dashboards#/view/$dashboardId"
