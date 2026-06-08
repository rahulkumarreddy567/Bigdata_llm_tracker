#!/usr/bin/env python3
"""
Script to create Kibana data views for LLM Tracker project
"""

import requests
import json
import time
import sys

KIBANA_URL = "http://localhost:5601"
HEADERS = {
    "kbn-xsrf": "true",
    "Content-Type": "application/json"
}

def wait_for_kibana(max_retries=30):
    """Wait for Kibana to be ready"""
    for i in range(max_retries):
        try:
            response = requests.get(f"{KIBANA_URL}/api/status", headers=HEADERS, timeout=5)
            if response.status_code == 200:
                print("✓ Kibana is ready")
                return True
        except requests.exceptions.ConnectionError:
            print(f"Waiting for Kibana... ({i+1}/{max_retries})")
            time.sleep(2)
    return False

def create_data_view(title, name, time_field="ingestion_date"):
    """Create a data view in Kibana"""
    payload = {
        "data_view": {
            "title": title,
            "name": name,
            "timeFieldName": time_field,
            "allowNoIndex": False
        }
    }
    
    try:
        response = requests.post(
            f"{KIBANA_URL}/api/data_views/data_views",
            headers=HEADERS,
            json=payload,
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            data_view_id = data.get('data_view', {}).get('id')
            print(f"✓ Data view created successfully!")
            print(f"  - ID: {data_view_id}")
            print(f"  - Title: {title}")
            print(f"  - Name: {name}")
            print(f"  - Time field: {time_field}")
            return True
        else:
            print(f"✗ Failed to create data view")
            print(f"  Status: {response.status_code}")
            print(f"  Response: {response.text}")
            return False
    except Exception as e:
        print(f"✗ Error creating data view: {e}")
        return False

def list_data_views():
    """List existing data views"""
    try:
        response = requests.get(
            f"{KIBANA_URL}/api/data_views",
            headers=HEADERS,
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            views = data.get('data_views', [])
            
            if views:
                print("\nExisting Data Views:")
                print("=" * 60)
                for view in views:
                    print(f"  Name: {view.get('name')}")
                    print(f"  Title: {view.get('title')}")
                    print(f"  ID: {view.get('id')}")
                    print(f"  Time Field: {view.get('timeFieldName')}")
                    print("-" * 60)
            else:
                print("\nNo data views found")
            return True
        else:
            print(f"Could not list data views: {response.status_code}")
            return False
    except Exception as e:
        print(f"Error listing data views: {e}")
        return False

def main():
    print("=" * 60)
    print("LLM Tracker - Kibana Data View Setup")
    print("=" * 60)
    print()
    
    # Wait for Kibana
    if not wait_for_kibana():
        print("✗ Kibana is not responding. Please start Kibana first.")
        sys.exit(1)
    
    print()
    
    # Create data view for llm_value_scores
    print("Creating data view for llm_value_scores...")
    if create_data_view(
        title="llm-value-scores*",
        name="LLM Value Scores",
        time_field="ingestion_date"
    ):
        print()
        print("✓ Data view created successfully!")
    else:
        print()
        print("✗ Failed to create data view")
        sys.exit(1)
    
    # List existing data views
    print()
    list_data_views()
    
    print()
    print("=" * 60)
    print("Next steps:")
    print("1. Open Kibana: http://localhost:5601")
    print("2. Go to: Stack Management → Data Views")
    print("3. Select: 'LLM Value Scores'")
    print("4. Create visualizations from the data")
    print("=" * 60)

if __name__ == "__main__":
    main()
