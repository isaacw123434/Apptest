import json
import os
import urllib.request
import urllib.error

# Function to fetch directions and get stops using Routes API
def fetch_transit_details(start_loc, end_loc, api_key):
    url = "https://routes.googleapis.com/directions/v2:computeRoutes"

    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": api_key,
        "X-Goog-FieldMask": "routes.legs.steps.transitDetails"
    }

    body = {
        "origin": {
            "location": {
                "latLng": {
                    "latitude": start_loc['lat'],
                    "longitude": start_loc['lng']
                }
            }
        },
        "destination": {
            "location": {
                "latLng": {
                    "latitude": end_loc['lat'],
                    "longitude": end_loc['lng']
                }
            }
        },
        "travelMode": "TRANSIT",
        "computeAlternativeRoutes": False
    }

    try:
        req = urllib.request.Request(url, data=json.dumps(body).encode('utf-8'), headers=headers, method='POST')
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())

        if not data.get('routes'):
            return None

        # Look for the transit step
        route = data['routes'][0]
        if not route.get('legs'):
            return None

        leg = route['legs'][0]

        max_stops = 0
        best_details = None

        for step in leg.get('steps', []):
            transit_details = step.get('transitDetails')
            if transit_details:
                stop_count = transit_details.get('stopCount', 0)
                # Keep the detail with the most stops, assuming it's the main leg
                if stop_count >= max_stops:
                    max_stops = stop_count
                    best_details = transit_details

        if best_details:
            num_stops = best_details.get('stopCount', 0)

            # stops list and stop_points list
            stops = []
            stop_points = []

            # Note: Routes API v2 stopDetails currently provides arrivalStop and departureStop.
            # It does not explicitly list intermediate stops in a 'stops' array in the standard response.
            # However, we implement logic to parse it if it becomes available or if we find it.

            stop_details = best_details.get('stopDetails')
            if stop_details:
                # If stopDetails becomes a list in future or some contexts:
                if isinstance(stop_details, list):
                    for stop in stop_details:
                        name = stop.get('name') or stop.get('stop', {}).get('name')
                        loc = stop.get('location') or stop.get('stop', {}).get('location')
                        if name: stops.append(name)
                        if loc and 'latLng' in loc:
                            stop_points.append({'lat': loc['latLng']['latitude'], 'lng': loc['latLng']['longitude']})

                # If stopDetails is an object (current behavior)
                elif isinstance(stop_details, dict):
                    # We could add departure/arrival, but those are redundant with leg start/end.
                    # We are looking for INTERMEDIATE stops.
                    pass

            return {
                'num_stops': num_stops,
                'stops': stops,
                'stop_points': stop_points
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

                            # Check if lists are different
                            current_stops = leg['transit_details'].get('stops', [])
                            new_stops = details['stops']

                            current_points = leg['transit_details'].get('stop_points', [])
                            new_points = details['stop_points']

                            # Update if any change
                            if (current_num != new_num or
                                current_stops != new_stops or
                                len(current_points) != len(new_points)): # Simplified check for points

                                print(f"  Updated num_stops: {current_num} -> {new_num}")
                                if new_stops:
                                    print(f"  Updated stops: {len(new_stops)} stops found")

                                leg['transit_details']['num_stops'] = new_num
                                leg['transit_details']['stops'] = new_stops
                                leg['transit_details']['stop_points'] = new_points
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
