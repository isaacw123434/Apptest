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

            stops = []
            stop_points = []

            # Extract stops from stopDetails if available
            stop_details = best_details.get('stopDetails')
            if stop_details:
                # 1. Check if it's a list (some providers might support this in future)
                if isinstance(stop_details, list):
                    for item in stop_details:
                        # TransitStopDetails contains arrivalStop and departureStop
                        # We are interested in the stop itself.
                        # If it's a list of stops, we assume each item wraps a stop info
                        # or is a TransitStopDetails object for a segment between stops?
                        # Based on typical API patterns, if it were a list of intermediate stops,
                        # it might look like a list of TransitStopDetails.

                        # Check arrivalStop
                        arrival_stop = item.get('arrivalStop', {})
                        name = arrival_stop.get('name')
                        loc = arrival_stop.get('location')

                        if name: stops.append(name)
                        if loc and 'latLng' in loc:
                            stop_points.append({'lat': loc['latLng']['latitude'], 'lng': loc['latLng']['longitude']})

                # 2. Check for standard Arrival/Departure (always present in current API)
                # We do not add these to stop_points to avoid duplicating start/end nodes.
                pass

            # Check for transit line URI as a potential source for more data
            transit_line = best_details.get('transitLine', {})
            uri = transit_line.get('uri')

            # Check agencies for URI if not on transitLine
            if not uri and transit_line.get('agencies'):
                for agency in transit_line['agencies']:
                    if agency.get('uri'):
                        uri = agency.get('uri')
                        break

            return {
                'num_stops': num_stops,
                'stops': stops,
                'stop_points': stop_points,
                'line_uri': uri
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

                            current_stops = leg['transit_details'].get('stops', [])
                            new_stops = details['stops']

                            current_points = leg['transit_details'].get('stop_points', [])
                            new_points = details['stop_points']

                            current_uri = leg['transit_details'].get('line_uri')
                            new_uri = details['line_uri']

                            # Update if any change
                            if (current_num != new_num or
                                current_stops != new_stops or
                                len(current_points) != len(new_points) or
                                current_uri != new_uri):

                                print(f"  Updated num_stops: {current_num} -> {new_num}")
                                if new_stops:
                                    print(f"  Updated stops: {len(new_stops)} stops found")
                                if new_uri:
                                    print(f"  Found Line URI: {new_uri}")

                                leg['transit_details']['num_stops'] = new_num
                                leg['transit_details']['stops'] = new_stops
                                leg['transit_details']['stop_points'] = new_points
                                if new_uri:
                                    leg['transit_details']['line_uri'] = new_uri
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
