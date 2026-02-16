import json
import math
import re

# Constants from Dart code
ICON_IDS = {
    'train': 'train',
    'car': 'car',
    'bus': 'bus',
    'bike': 'bike',
    'footprints': 'footprints',
    'parking': 'parking'
}

PRICING = {
    'brough': {'parking': 5.80, 'uber': 22.58, 'train': 8.10},
    'york': {'parking': 13.80, 'uber': 46.24, 'train': 5.20},
    'beverley': {'parking': 4.40, 'uber': 4.62, 'train': 12.10},
    'hull': {'parking': 6.00, 'uber': 20.63, 'train': 9.60},
    'eastrington': {'parking': 0.00, 'uber': 34.75, 'train': 7.00},
}

def decode_polyline(polyline_str):
    index, lat, lng = 0, 0, 0
    coordinates = []
    changes = {'latitude': 0, 'longitude': 0}

    while index < len(polyline_str):
        for unit in ['latitude', 'longitude']:
            shift, result = 0, 0

            while True:
                byte = ord(polyline_str[index]) - 63
                index += 1
                result |= (byte & 0x1f) << shift
                shift += 5
                if not byte >= 0x20:
                    break

            if (result & 1):
                changes[unit] = ~(result >> 1)
            else:
                changes[unit] = (result >> 1)

        lat += changes['latitude']
        lng += changes['longitude']

        coordinates.append([lat / 100000.0, lng / 100000.0])

    return coordinates

def get_emission_factor(icon_id):
    if icon_id == ICON_IDS['train']: return 0.06
    if icon_id == ICON_IDS['bus']: return 0.10
    if icon_id == ICON_IDS['car']: return 0.27
    return 0.0

def calculate_emission(distance_miles, icon_id):
    return distance_miles * get_emission_factor(icon_id)

def get_bus_cost(label):
    lower = label.lower()
    if re.search(r'\bx1\b', lower) or re.search(r'\bx46\b', lower):
        return 3.00
    if re.search(r'\bpr\d+\b', lower):
        return 5.00
    return 2.00

def map_mode(raw_mode, transit_details):
    raw_mode = raw_mode.lower()
    if raw_mode == 'walking': return 'walk'
    if raw_mode == 'driving': return 'car'
    if raw_mode == 'bicycling': return 'bike'
    if raw_mode == 'transit':
        if transit_details:
            vehicle_type = transit_details.get('vehicle_type')
            if not vehicle_type and transit_details.get('line') and transit_details['line'].get('vehicle'):
                vehicle_type = transit_details['line']['vehicle'].get('type')

            if vehicle_type:
                vehicle_type = vehicle_type.upper()
                if vehicle_type == 'BUS': return 'bus'
                if vehicle_type in ['HEAVY_RAIL', 'TRAIN']: return 'train'
        return 'bus'
    return raw_mode

def parse_segment(json_segment, option_name, route_id):
    raw_mode = json_segment.get('mode', '').lower()
    transit_details = json_segment.get('transit_details')
    mode = map_mode(raw_mode, transit_details)
    polyline = json_segment.get('polyline', '')
    path = decode_polyline(polyline)

    label = mode
    line_color = '#000000'
    icon_id = ICON_IDS['footprints']
    from_loc = None
    to_loc = None

    if transit_details:
        if 'departure_stop' in transit_details:
            from_loc = transit_details['departure_stop']['name']
        if 'arrival_stop' in transit_details:
            to_loc = transit_details['arrival_stop']['name']

        color = transit_details.get('color')
        if 'line' in transit_details and 'color' in transit_details['line']:
            color = transit_details['line']['color']
        if color:
            line_color = color

        line_name = transit_details.get('line_name')
        if 'line' in transit_details:
            line_name = transit_details['line'].get('short_name')
            if not line_name and 'agencies' in transit_details['line']:
                agencies = transit_details['line']['agencies']
                if agencies:
                    line_name = agencies[0].get('name')
            if not line_name:
                line_name = transit_details['line'].get('name')

        vehicle_type = transit_details.get('vehicle_type')
        if 'line' in transit_details and 'vehicle' in transit_details['line']:
            vehicle_type = transit_details['line']['vehicle'].get('name')

        label = line_name or vehicle_type or mode

        if mode == 'bus': icon_id = ICON_IDS['bus']
        if mode == 'train': icon_id = ICON_IDS['train']

        if mode == 'bus' and re.match(r'^\d+$', str(label)):
            label = f'Bus {label}'
    else:
        if mode in ['car', 'taxi']:
            icon_id = ICON_IDS['car']
            if 'uber' in option_name.lower():
                label = 'Uber'
                line_color = '#000000'
            else:
                label = 'Drive'
                line_color = '#0000FF'
        elif mode == 'bike':
            icon_id = ICON_IDS['bike']
            line_color = '#00FF00'
        elif mode == 'walk':
            icon_id = ICON_IDS['footprints']
            line_color = '#475569'

        instructions = json_segment.get('instructions', '')
        if instructions:
            from_match = re.search(r'from\s+(.*?)(?=\s+to\s+|$)', instructions, re.IGNORECASE)
            if from_match:
                from_loc = from_match.group(1)
            to_match = re.search(r'to\s+(.*?)(?=$)', instructions, re.IGNORECASE)
            if to_match:
                to_loc = to_match.group(1)

    if label:
        label = label[0].upper() + label[1:]

    dist_miles = json_segment.get('distance_value', 0) / 1609.34

    cost = 0.0
    if mode == 'car':
        if 'uber' in label.lower() or 'uber' in option_name.lower():
            cost = 0.00
        else:
            cost = 0.45 * dist_miles
    elif mode == 'bus':
        cost = get_bus_cost(label)
    elif mode == 'train':
        cost = 0.00

    return {
        'mode': mode,
        'label': label,
        'lineColor': line_color,
        'iconId': icon_id,
        'time': round(json_segment.get('duration_value', 0) / 60),
        'path': path,
        'distance': dist_miles,
        'co2': calculate_emission(dist_miles, icon_id),
        'from': from_loc,
        'to': to_loc,
        'cost': cost
    }

def should_merge(a, b):
    if a['mode'] == b['mode'] and a['label'] == b['label']:
        if a['mode'] == 'train': return False
        return True
    return False

def merge_segments(a, b):
    new_path = []
    if a.get('path'): new_path.extend(a['path'])
    if b.get('path'): new_path.extend(b['path'])

    new_time = a['time'] + b['time']
    new_dist = (a.get('distance') or 0) + (b.get('distance') or 0)
    new_co2 = (a.get('co2') or 0) + (b.get('co2') or 0)
    new_cost = a['cost'] + b['cost']

    merged = a.copy()
    merged.update({
        'time': new_time,
        'path': new_path,
        'distance': new_dist,
        'co2': new_co2,
        'cost': new_cost
    })
    return merged

def calculate_risk(group_name, option_name):
    lower_group = group_name.lower()
    lower_option = option_name.lower()

    if 'group 1' in lower_group:
        if 'cycle' in lower_option: return {'score': 1, 'reason': 'Weather dependent, fitness required'}
        if 'bus' in lower_option: return {'score': 0, 'reason': 'Frequent, reliable'}
        if 'uber' in lower_option or 'drive' in lower_option: return {'score': 0, 'reason': 'Most reliable'}

    if 'group 2' in lower_group:
        if 'bus' in lower_option and 'train' in lower_option:
            return {'score': 2, 'reason': 'Bus risk (+1) + Connection risk (+1)'}
        if 'p&r' in lower_option:
            return {'score': 1, 'reason': 'Connection risk'}
        if 'walk' in lower_option and 'train' in lower_option:
            return {'score': 2, 'reason': 'Timing risk (+1) + Connection risk (+1)'}
        if 'cycle' in lower_option and 'train' in lower_option:
            return {'score': 1, 'reason': 'Weather dependent, connection risk'}
        if ('uber' in lower_option or 'drive' in lower_option) and 'train' in lower_option:
            return {'score': 1, 'reason': 'Connection risk'}

    if 'group 3' in lower_group:
        if 'train' in lower_option: return {'score': 1, 'reason': 'Delay/timing risk'}

    if 'group 4' in lower_group:
        if 'bus' in lower_option: return {'score': 2, 'reason': 'Unfamiliar area, less frequent'}
        if 'uber' in lower_option: return {'score': 0, 'reason': 'Most reliable'}
        if 'cycle' in lower_option: return {'score': 1, 'reason': 'Weather dependent, fitness required'}

    if 'group 5' in lower_group:
        return {'score': 0, 'reason': 'Most reliable'}

    return {'score': 0, 'reason': 'Standard risk'}

def generate_id(name):
    lower = name.lower()
    hub = None
    if 'brough' in lower: hub = 'brough'
    elif 'york' in lower: hub = 'york'
    elif 'beverley' in lower: hub = 'beverley'
    elif 'hull' in lower: hub = 'hull'
    elif 'eastrington' in lower: hub = 'eastrington'
    elif 'headingley' in lower: hub = 'headingley'

    if 'p&r' in lower or 'park & ride' in lower:
        if 'stourton' in lower: return 'drive_stourton_pr'
        if 'temple green' in lower: return 'drive_temple_green_pr'
        if 'elland road' in lower: return 'drive_elland_road_pr'
        return 'drive_pr'

    if 'train' in lower:
        if hub:
            if 'walk' in lower: return f'train_walk_{hub}'
            if 'cycle' in lower: return f'train_cycle_{hub}'
            if 'uber' in lower: return f'train_uber_{hub}'
            if 'drive' in lower: return f'train_drive_{hub}'
            if 'bus' in lower: return f'train_bus_{hub}'
            return f'train_{hub}'
        if 'walk' in lower: return 'train_walk_headingley'
        if 'cycle' in lower: return 'train_cycle_headingley'
        if 'uber' in lower: return 'train_uber_headingley'
        if 'drive' in lower: return 'train_drive'
        if 'bus' in lower: return 'train_bus'
        return 'train_main'

    if 'uber' in lower: return 'uber'
    if 'bus' in lower: return 'bus'
    if 'cycle' in lower: return 'cycle'
    if 'direct drive' in lower: return 'direct_drive'
    if 'drive' in lower: return 'drive'

    return re.sub(r'[^a-zA-Z0-9]', '_', name).lower()

def map_icon_id(name, segments):
    lower = name.lower()
    if 'uber' in lower: return ICON_IDS['car']
    if 'bus' in lower: return ICON_IDS['bus']
    if 'cycle' in lower: return ICON_IDS['bike']
    if 'train' in lower:
        if 'walk' in lower: return ICON_IDS['footprints']
        if 'cycle' in lower: return ICON_IDS['bike']
        if 'uber' in lower: return ICON_IDS['car']
        if 'drive' in lower: return ICON_IDS['car']
        if 'bus' in lower: return ICON_IDS['bus']
        return ICON_IDS['train']
    if 'walk' in lower: return ICON_IDS['footprints']
    return ICON_IDS['car']

def map_line_color(name, segments):
    lower = name.lower()
    if 'cycle' in lower: return '#00FF00'
    for seg in segments:
        if seg['mode'] == 'train': return seg['lineColor']
        if seg['mode'] == 'bus': return seg['lineColor']
    return '#000000'

def generate_detail(segments):
    parts = []
    for seg in segments:
        if seg['time'] > 0:
            parts.append(f"{seg['time']} min {seg['mode']}")
    return ' then '.join(parts)

def parse_option_to_leg(option, group_name, route_id):
    name = option.get('name', 'Unknown')
    json_legs = option.get('legs', [])

    raw_segments = []
    for json_leg in json_legs:
        raw_segments.append(parse_segment(json_leg, name, route_id))

    # --- Routes Parser Filtering (Short walks <= 1 min) ---
    filtered_segments = []
    for seg in raw_segments:
        if seg['mode'] == 'walk' and seg['time'] <= 1:
            continue
        filtered_segments.append(seg)

    # --- Routes Parser Merging (Consecutive same mode) ---
    merged_segments = []
    for seg in filtered_segments:
        if merged_segments:
            last = merged_segments[-1]
            if should_merge(last, seg):
                merged_segments[-1] = merge_segments(last, seg)
                continue
        merged_segments.append(seg)

    # --- Location detection for Pricing ---
    location = None
    for seg in merged_segments:
        if seg['mode'] == 'train' and seg.get('from'):
            parts = seg['from'].lower().split(' ')
            loc = parts[0]
            if 'eastrington' in seg['from'].lower(): loc = 'eastrington'
            location = loc
            break

    if not location:
        lower_name = name.lower()
        if 'brough' in lower_name: location = 'brough'
        elif 'york' in lower_name: location = 'york'
        elif 'beverley' in lower_name: location = 'beverley'
        elif 'hull' in lower_name: location = 'hull'
        elif 'eastrington' in lower_name: location = 'eastrington'

    if not location:
        lower_group = group_name.lower()
        if 'brough' in lower_group: location = 'brough'
        elif 'york' in lower_group: location = 'york'
        elif 'beverley' in lower_group: location = 'beverley'
        elif 'hull' in lower_group: location = 'hull'
        elif 'eastrington' in lower_group: location = 'eastrington'

    # --- Routes Parser: Insert Parking Segment ---
    # We want to PRE-MERGE parking into car if possible, or insert it if it's a separate step?
    # Original logic: Insert parking segment.
    # DetailPage logic: Merge parking cost into previous car segment and hide parking segment.
    # So we should just update the cost of the car segment.

    final_segments_step1 = []
    i = 0
    while i < len(merged_segments):
        current = merged_segments[i]
        final_segments_step1.append(current)

        if current['mode'] == 'car':
            connects_to_train = False
            for j in range(i + 1, len(merged_segments)):
                if merged_segments[j]['mode'] == 'train':
                    connects_to_train = True
                    break
                if merged_segments[j]['mode'] in ['bus', 'car']:
                    break

            if connects_to_train:
                is_uber = 'uber' in current['label'].lower()
                if not is_uber:
                    parking_cost = 5.00
                    if location and location in PRICING:
                        parking_cost = PRICING[location].get('parking', 5.00)

                    # Merge cost into car segment directly
                    current['cost'] += parking_cost
                    # Do NOT add a parking segment
        i += 1

    merged_segments = final_segments_step1

    # --- Routes Parser: Transfer Buffer for Route 2 ---
    if route_id == 'route2' and 'Access Options' in group_name and 'train' in name.lower():
        # Inject wait time into the previous segment or next segment?
        # Routes parser inserts a 'wait' segment.
        # DetailPage displays "10 mins transfer".
        # We can keep the 'wait' segment because it is meaningful info.

        train_index = -1
        for idx, seg in enumerate(merged_segments):
            if seg['mode'] == 'train':
                train_index = idx
                break

        if train_index != -1:
            merged_segments.insert(train_index, {
                'mode': 'wait',
                'label': 'Transfer',
                'lineColor': '#000000',
                'iconId': 'clock',
                'time': 10,
                'detail': 'Transfer Buffer',
                'cost': 0.0,
                'distance': 0.0,
                'co2': 0.0
            })

    # --- Routes Parser: Apply Specific Pricing ---
    if location and location in PRICING:
        prices = PRICING[location]
        train_cost_applied = False
        uber_cost_applied = False

        for seg in merged_segments:
            if seg['mode'] == 'train' and 'train' in prices:
                seg['cost'] = 0.0 if train_cost_applied else prices['train']
                train_cost_applied = True
            if seg['mode'] == 'car' and 'uber' in seg['label'].lower() and 'uber' in prices:
                seg['cost'] = 0.0 if uber_cost_applied else prices['uber']
                uber_cost_applied = True

    # --- Routes Parser: Logic Overrides (St Chads, etc) ---
    if route_id == 'route1':
        # Drive to Leeds -> Add Parking £23
        if 'Group 1' in group_name and name.lower() == 'drive':
             # Find car segment and add cost
             for seg in merged_segments:
                 if seg['mode'] == 'car':
                     seg['cost'] += 23.00
                     # No parking segment added

        if name.lower() == 'uber' and 'Group 1' in group_name:
             for seg in merged_segments:
                 if seg['mode'] == 'car' or 'uber' in seg['label'].lower():
                     seg['cost'] = 8.97
                     break

        if 'Walk' in name and 'Train' in name:
            train_applied = False
            for seg in merged_segments:
                if seg['mode'] == 'train':
                    seg['cost'] = 0.0 if train_applied else 3.40
                    train_applied = True

        if 'Uber' in name and 'Train' in name:
            uber_applied = False
            train_applied = False
            for seg in merged_segments:
                if seg['mode'] == 'car' or 'uber' in seg['label']:
                    seg['cost'] = 0.0 if uber_applied else 5.92
                    uber_applied = True
                elif seg['mode'] == 'train':
                    seg['cost'] = 0.0 if train_applied else 3.40
                    train_applied = True

        if 'bus' in name.lower():
            for seg in merged_segments:
                if seg['mode'] == 'bus':
                    seg['cost'] = get_bus_cost(seg['label'])

        if 'Group 3' in group_name:
            train_applied = False
            for seg in merged_segments:
                if seg['mode'] == 'train':
                    seg['cost'] = 0.0 if train_applied else 25.70
                    train_applied = True

        if 'Group 4' in group_name:
            if 'bus' in name.lower():
                for seg in merged_segments:
                    if seg['mode'] == 'bus':
                        seg['cost'] = get_bus_cost(seg['label'])
            if 'uber' in name.lower():
                uber_applied = False
                for seg in merged_segments:
                    if seg['mode'] == 'car' or 'uber' in seg['label']:
                        seg['cost'] = 0.0 if uber_applied else 14.89
                        uber_applied = True

    # --- Routes Parser: P&R Logic (Route 2) ---
    if route_id == 'route2' and ('park & ride' in name.lower() or 'p&r' in name.lower()):
        # Originally adds parking segment if missing.
        # But we are merging parking cost into car.
        # Is there a car segment?
        car_segments = [s for s in merged_segments if s['mode'] == 'car']
        if car_segments:
            # P&R cost is 5.00 + 0.45*dist (handled in estimate_cost but also here?)
            # The parking segment in original logic had cost 0.00 here?
            # "mergedSegments.insert(..., Segment(..., cost: 0.00))"
            # So no extra cost to add.
            pass

    # --- DetailPage: Filter out 4 mins walk between trains ---
    # Logic: if isWalk && seg.time <= 5 && prevIsTrain && nextIsTrain -> Remove and Add time to next train (as waitTime?)

    final_segments_step2 = []
    i = 0
    while i < len(merged_segments):
        seg = merged_segments[i]
        should_hide = False
        is_walk = seg['mode'] == 'walk' or seg['iconId'] == ICON_IDS['footprints']

        wait_time_to_add = 0

        # Issue 2: Filter out 4 mins walk between trains
        if is_walk and seg['time'] <= 5:
            prev_is_train = False
            if i > 0:
                prev = merged_segments[i-1]
                if prev['iconId'] == ICON_IDS['train']:
                    prev_is_train = True

            next_is_train = False
            if i < len(merged_segments) - 1:
                nxt = merged_segments[i+1]
                if nxt['iconId'] == ICON_IDS['train']:
                    next_is_train = True

            if prev_is_train and next_is_train:
                should_hide = True
                wait_time_to_add = seg['time']

        # Also filter very short walks (DetailPage threshold 2.5)
        # We already filtered <= 1 min. So this is 1 < time < 2.5 (i.e. 2 mins)
        walk_threshold = 2.5
        if not should_hide and is_walk and seg['time'] < walk_threshold:
            should_hide = True
            wait_time_to_add = seg['time']

        if should_hide:
            # Add time to next segment as waitTime
            if i < len(merged_segments) - 1:
                next_seg = merged_segments[i+1]
                current_wait = next_seg.get('waitTime', 0)
                next_seg['waitTime'] = current_wait + wait_time_to_add
            pass
        else:
            final_segments_step2.append(seg)
        i += 1

    merged_segments = final_segments_step2

    # --- Recalculate totals ---
    final_dist = 0
    final_time = 0
    total_co2 = 0
    total_cost = 0

    for seg in merged_segments:
        final_dist += seg.get('distance', 0)
        final_time += seg['time']
        if seg.get('waitTime'):
            final_time += seg['waitTime']

        total_co2 += seg.get('co2', 0)
        total_cost += seg['cost']

    # Calculate Risk
    risk = calculate_risk(group_name, name)

    # Map IDs etc
    id_val = generate_id(name)
    icon_id = map_icon_id(name, merged_segments)
    line_color = map_line_color(name, merged_segments)

    # Generate Detail (Truncated for Route 2 Access Options)
    detail_segments = merged_segments
    if route_id == 'route2' and 'Access Options' in group_name:
        filtered = []
        is_pr = 'p&r' in name.lower() or 'park & ride' in name.lower()
        for seg in merged_segments:
            if seg['mode'] == 'train':
                break
            if seg['mode'] == 'wait':
                break
            if is_pr and seg['mode'] == 'bus':
                break
            filtered.append(seg)
        if filtered:
            detail_segments = filtered

    detail = generate_detail(detail_segments)

    # Standardise Labels
    final_label = name
    if route_id == 'route1':
        # Only rename First Mile options (Group 1)
        if 'Group 1' in group_name:
             if name == 'Drive':
                 final_label = 'Drive & Park'
                 id_val = 'drive_park' # Override ID to match frontend expectation
             elif name in ['Bus', 'Cycle', 'Uber']:
                 final_label = f'{name} to Leeds'

    elif route_id == 'route2':
        final_label = name.replace(' + Train', '')

    # --- Enrich Data (Colors, Desc, Recommended) ---
    color = None
    bg_color = None
    desc = None
    recommended = None
    wait_time = None
    next_bus_in = None
    platform = None

    # Logic based on ID or Mode
    if id_val == 'uber' or id_val == 'last_uber':
        color = 'text-black'
        bg_color = 'bg-zinc-100'
        if 'Group 1' in group_name:
            desc = 'Fastest door-to-door.'
            wait_time = 4
        elif 'Group 4' in group_name:
            desc = 'Reliable final leg.'

    elif id_val == 'bus' or id_val == 'last_bus':
        color = 'text-brand-dark'
        bg_color = 'bg-brand-light'
        if 'Group 1' in group_name:
            desc = 'Best balance.'
            recommended = True
            next_bus_in = 12
        elif 'Group 4' in group_name:
            desc = 'Short walk required.'
            recommended = True

    elif id_val == 'drive_park' or id_val == 'drive':
        color = 'text-zinc-800'
        bg_color = 'bg-zinc-100'
        desc = 'Flexibility.'

    elif id_val == 'train_walk_headingley':
        color = 'text-slate-600'
        bg_color = 'bg-slate-100'
        desc = 'Walking transfer.'

    elif id_val == 'train_uber_headingley':
        color = 'text-slate-600'
        bg_color = 'bg-slate-100'
        desc = 'Fast transfer.'
        wait_time = 3

    elif id_val == 'cycle' or id_val == 'last_cycle':
        color = 'text-blue-600'
        bg_color = 'bg-blue-100'
        if 'Group 1' in group_name:
             desc = 'Zero emissions.'
        elif 'Group 4' in group_name:
             desc = 'Scenic route.'

    elif id_val == 'train_main':
        color = 'text-[#713e8d]'
        bg_color = 'bg-indigo-100'
        platform = 4

    # Default Logic
    if not color:
        if icon_id == ICON_IDS['train']:
            color = 'text-slate-600'
            bg_color = 'bg-slate-100'
        elif icon_id == ICON_IDS['bus']:
            color = 'text-brand-dark'
            bg_color = 'bg-brand-light'
        elif icon_id == ICON_IDS['car']:
            color = 'text-black'
            bg_color = 'bg-zinc-100'
        elif icon_id == ICON_IDS['bike']:
            color = 'text-blue-600'
            bg_color = 'bg-blue-100'
        elif icon_id == ICON_IDS['footprints']:
            color = 'text-slate-600'
            bg_color = 'bg-slate-100'


    return {
        'id': id_val,
        'label': final_label,
        'detail': detail,
        'time': final_time,
        'cost': total_cost,
        'distance': float(f"{final_dist:.2f}"),
        'riskScore': risk['score'],
        'riskReason': risk['reason'],
        'iconId': icon_id,
        'lineColor': line_color,
        'segments': merged_segments,
        'co2': float(f"{total_co2:.2f}"),
        'color': color,
        'bgColor': bg_color,
        'desc': desc,
        'recommended': recommended,
        'waitTime': wait_time,
        'nextBusIn': next_bus_in,
        'platform': platform
    }

def process_file(input_path, output_path, route_id):
    with open(input_path, 'r') as f:
        data = json.load(f)

    groups = data.get('groups', [])

    first_mile = []
    main_leg = None
    last_mile = []
    direct_drive = None
    mock_path = []

    for group in groups:
        name = group.get('name', '')
        options = group.get('options', [])

        if 'Group 1' in name or 'Group 2' in name:
            for option in options:
                first_mile.append(parse_option_to_leg(option, name, route_id))
        elif 'Group 3' in name:
            if options:
                main_leg = parse_option_to_leg(options[0], name, route_id)
        elif 'Group 4' in name:
            for option in options:
                last_mile.append(parse_option_to_leg(option, name, route_id))
        elif 'Group 5' in name:
            if options:
                # Direct Drive logic from Routes Parser
                direct_option = options[0]
                total_duration_seconds = 0
                total_dist_meters = 0
                full_path = []
                legs = direct_option.get('legs', [])

                for leg in legs:
                    total_duration_seconds += leg.get('duration_value', 0)
                    total_dist_meters += leg.get('distance_value', 0)
                    poly = leg.get('polyline', '')
                    if poly:
                        full_path.extend(decode_polyline(poly))

                total_dist_miles = total_dist_meters / 1609.34
                mock_path = full_path

                # Estimate cost
                # _estimateCost('Direct Drive', ...) -> 0.45 * distance
                cost = 0.45 * total_dist_miles

                direct_drive = {
                    'time': round(total_duration_seconds / 60),
                    'cost': cost,
                    'distance': float(f"{total_dist_miles:.2f}"),
                    'co2': calculate_emission(total_dist_miles, ICON_IDS['car'])
                }

    if not main_leg:
        main_leg = {'id': 'main_placeholder', 'label': 'Main', 'segments': [], 'time': 0, 'cost': 0, 'distance': 0, 'riskScore': 0, 'iconId': 'train', 'lineColor': '#000000'}

    if not direct_drive:
        direct_drive = {'time': 0, 'cost': 0, 'distance': 0}

    init_data = {
        'segmentOptions': {
            'firstMile': first_mile,
            'mainLeg': main_leg,
            'lastMile': last_mile
        },
        'directDrive': direct_drive,
        'mockPath': mock_path
    }

    with open(output_path, 'w') as f:
        json.dump(init_data, f, indent=2)

def main():
    print("Processing routes...")
    process_file('client/assets/routes.json', 'client/assets/routes_clean.json', 'route1')
    process_file('client/assets/routes_2.json', 'client/assets/routes_2_clean.json', 'route2')
    print("Done.")

if __name__ == '__main__':
    main()
