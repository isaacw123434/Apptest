import json
import os
import urllib.request
import urllib.parse
import sys

# Function to fetch directions and get stops
def fetch_transit_details(start_loc, end_loc, api_key):
    base_url = "https://maps.googleapis.com/maps/api/directions/json"
    params = {
        "origin": f"{start_loc['lat']},{start_loc['lng']}",
        "destination": f"{end_loc['lat']},{end_loc['lng']}",
        "mode": "transit",
        "key": api_key,
    }

    url = f"{base_url}?{urllib.parse.urlencode(params)}"

    try:
        with urllib.request.urlopen(url) as response:
            data = json.loads(response.read().decode())

        if data['status'] == 'OK':
            if not data['routes']:
                return None

            leg = data['routes'][0]['legs'][0]

            for step in leg['steps']:
                if step.get('travel_mode') == 'TRANSIT':
                    transit_details = step.get('transit_details', {})
                    num_stops = transit_details.get('num_stops', 0)
                    # Note: Google Maps Directions API (standard) does not provide coordinates for intermediate stops.
                    # 'stops' list is therefore returned empty.
                    return {
                        'num_stops': num_stops,
                        'stops': []
                    }

    except Exception as e:
        print(f"Error fetching directions: {e}")
        return None

    return None

def process_file(filepath, api_key):
    print(f"Processing {filepath}...")
    with open(filepath, 'r') as f:
        data = json.load(f)

    updated = False

    for group in data.get('groups', []):
        for option in group.get('options', []):
            for leg in option.get('legs', []):
                if leg.get('mode') == 'transit':
                    start = leg.get('start_location')
                    end = leg.get('end_location')

                    if start and end:
                        line_name = leg.get('transit_details', {}).get('line_name', 'Unknown')
                        print(f"Fetching transit details for {option['name']} ({line_name})...")

                        details = fetch_transit_details(start, end, api_key)
                        if details:
                            if 'transit_details' not in leg:
                                leg['transit_details'] = {}

                            current_num = leg['transit_details'].get('num_stops')
                            new_num = details['num_stops']

                            # Only update if changed or new
                            if current_num != new_num:
                                print(f"  Updated num_stops: {current_num} -> {new_num}")
                                leg['transit_details']['num_stops'] = new_num
                                updated = True

    if updated:
        with open(filepath, 'w') as f:
            json.dump(data, f, indent=2)
        print(f"Updated {filepath}")
    else:
        print(f"No changes for {filepath}")

def main():
    api_key = os.environ.get('Googlemapsapi')
    if not api_key:
        print("Error: Googlemapsapi environment variable not set.")
        return

    process_file('client/assets/routes.json', api_key)
    process_file('client/assets/routes_2.json', api_key)

if __name__ == "__main__":
    main()
