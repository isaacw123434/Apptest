import json
import os
import urllib.request
import urllib.parse
import sys

API_KEY = os.environ.get('Googlemapsapi')
if not API_KEY:
    print("Error: Googlemapsapi environment variable not found.")
    sys.exit(1)

ROUTES_FILE = 'client/assets/routes_2.json'
DESTINATION = "Wellington Place, Leeds"

def get_directions(origin, destination, mode):
    base_url = "https://maps.googleapis.com/maps/api/directions/json"
    params = {
        "origin": origin,
        "destination": destination,
        "mode": mode.lower(),
        "key": API_KEY
    }
    url = f"{base_url}?{urllib.parse.urlencode(params)}"
    print(f"Fetching directions: {mode} from {origin} to {destination}")

    try:
        with urllib.request.urlopen(url) as response:
            data = json.loads(response.read().decode())
            if data['status'] != 'OK':
                print(f"Error fetching directions: {data['status']}")
                if 'error_message' in data:
                    print(data['error_message'])
                return None

            route = data['routes'][0]
            leg = route['legs'][0]
            return {
                "polyline": route['overview_polyline']['points'],
                "distance_text": leg['distance']['text'],
                "distance_value": leg['distance']['value'],
                "duration_text": leg['duration']['text'],
                "duration_value": leg['duration']['value']
            }
    except Exception as e:
        print(f"Exception: {e}")
        return None

def update_routes():
    try:
        with open(ROUTES_FILE, 'r') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: {ROUTES_FILE} not found.")
        sys.exit(1)

    # 1. Update Park and Ride Walking Legs
    groups = data.get('groups', [])
    for group in groups:
        if group.get('name') == "Group 2: Access Options":
            for option in group.get('options', []):
                name = option.get('name', '')
                if "P&R" in name:
                    legs = option.get('legs', [])
                    if len(legs) >= 4:
                        # Leg 3 (index 2) is TRANSIT
                        transit_leg = legs[2]
                        if transit_leg.get('mode') == 'TRANSIT' and 'transit_details' in transit_leg:
                            arrival_stop = transit_leg['transit_details'].get('arrival_stop')
                            if arrival_stop and 'location' in arrival_stop:
                                lat = arrival_stop['location']['lat']
                                lng = arrival_stop['location']['lng']
                                origin = f"{lat},{lng}"

                                # Leg 4 (index 3) is WALKING (to be updated)
                                print(f"Updating P&R Walking leg for: {name}")
                                new_data = get_directions(origin, DESTINATION, "walking")
                                if new_data:
                                    # Preserve existing structure but update specific fields
                                    walking_leg = legs[3]
                                    walking_leg['polyline'] = new_data['polyline']
                                    walking_leg['distance_text'] = new_data['distance_text']
                                    walking_leg['distance_value'] = new_data['distance_value']
                                    walking_leg['duration_text'] = new_data['duration_text']
                                    walking_leg['duration_value'] = new_data['duration_value']
                                    walking_leg['mode'] = "WALKING" # Ensure mode is set
                                    walking_leg['instructions'] = f"Walk to {DESTINATION}"
                        else:
                             print(f"Skipping {name}: Leg 2 is not TRANSIT or missing details.")
                    else:
                        print(f"Skipping {name}: Not enough legs ({len(legs)})")

        elif group.get('name') == "Group 4: Final Mile":
            start_point = "53.795429,-1.548735"
            for option in group.get('options', []):
                name = option.get('name', '')
                legs = option.get('legs', [])
                if legs:
                    leg = legs[0]
                    mode = "walking"
                    if name == "Cycle":
                        mode = "bicycling"
                    elif name == "Walk":
                        mode = "walking"

                    print(f"Updating Final Mile: {name} ({mode})")
                    new_data = get_directions(start_point, DESTINATION, mode)
                    if new_data:
                        leg['polyline'] = new_data['polyline']
                        leg['distance_text'] = new_data['distance_text']
                        leg['distance_value'] = new_data['distance_value']
                        leg['duration_text'] = new_data['duration_text']
                        leg['duration_value'] = new_data['duration_value']

                        if name == "Cycle":
                             leg['mode'] = "BICYCLING"
                        else:
                             leg['mode'] = "WALKING"

                        leg['instructions'] = f"{mode.capitalize()} from Leeds Station to {DESTINATION}"

    with open(ROUTES_FILE, 'w') as f:
        json.dump(data, f, indent=2)
    print("Routes updated successfully.")

if __name__ == "__main__":
    update_routes()
