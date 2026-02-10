// Converted from src/services/journeyService.js

const ICON_IDS = {
  TRAIN: 'train',
  CAR: 'car',
  BUS: 'bus',
  BIKE: 'bike',
  FOOTPRINTS: 'footprints'
};

const SEGMENT_OPTIONS = {
  firstMile: [
    {
      id: 'uber',
      label: 'Uber',
      detail: 'St Chads → Leeds Station',
      time: 14,
      cost: 8.97,
      distance: 3,
      riskScore: 0,
      iconId: ICON_IDS.CAR,
      color: 'text-black',
      bgColor: 'bg-zinc-100',
      lineColor: '#000000',
      desc: 'Fastest door-to-door.',
      waitTime: 4,
      segments: [
        { mode: 'taxi', label: 'Uber', lineColor: '#000000', iconId: ICON_IDS.CAR, time: 14, to: 'Leeds Station' }
      ]
    },
    {
      id: 'bus',
      label: 'Bus (Line 24)',
      detail: '5min walk + 16min bus',
      time: 23,
      cost: 2.00,
      distance: 3,
      riskScore: 0,
      iconId: ICON_IDS.BUS,
      color: 'text-brand-dark', // updated color usage
      bgColor: 'bg-brand-light', // updated color usage
      lineColor: '#0f766e',
      recommended: true,
      desc: 'Best balance.',
      nextBusIn: 12,
      segments: [
        { mode: 'bus', label: 'Bus', lineColor: '#0f766e', iconId: ICON_IDS.BUS, time: 23, to: 'Leeds Station' }
      ]
    },
    {
      id: 'drive_park',
      label: 'Drive & Park',
      detail: 'Drive to Station',
      time: 15,
      cost: 24.89,
      distance: 3,
      riskScore: 0,
      iconId: ICON_IDS.CAR,
      color: 'text-zinc-800',
      bgColor: 'bg-zinc-100',
      lineColor: '#3f3f46',
      desc: 'Flexibility.',
      segments: [
        { mode: 'car', label: 'Drive', lineColor: '#3f3f46', iconId: ICON_IDS.CAR, time: 15, to: 'Leeds Station' }
      ]
    },
    {
      id: 'train_walk_headingley',
      label: 'Headingley (Walk)',
      detail: '18m Walk + 10m Train',
      time: 28,
      cost: 3.40,
      distance: 3,
      riskScore: 2, // Walk(+1) + Train(+1)
      iconId: ICON_IDS.FOOTPRINTS,
      color: 'text-slate-600',
      bgColor: 'bg-slate-100',
      lineColor: '#1d4ed8',
      desc: 'Walking transfer.',
      segments: [
        { mode: 'walk', label: 'Walk', lineColor: '#475569', iconId: ICON_IDS.FOOTPRINTS, time: 18, to: 'Headingley Station' },
        { mode: 'train', label: 'Northern', lineColor: '#1d4ed8', iconId: ICON_IDS.TRAIN, time: 10, to: 'Leeds Station' }
      ]
    },
    {
      id: 'train_uber_headingley',
      label: 'Uber + Northern',
      detail: '5m Uber + 10m Train',
      time: 15,
      cost: 9.32,
      distance: 3,
      riskScore: 1, // Uber(0) + Train(+1)
      iconId: ICON_IDS.CAR,
      color: 'text-slate-600',
      bgColor: 'bg-slate-100',
      lineColor: '#1d4ed8',
      desc: 'Fast transfer.',
      waitTime: 3,
      segments: [
        { mode: 'taxi', label: 'Uber', lineColor: '#000000', iconId: ICON_IDS.CAR, time: 5, to: 'Headingley Station' },
        { mode: 'train', label: 'Northern', lineColor: '#1d4ed8', iconId: ICON_IDS.TRAIN, time: 10, to: 'Leeds Station' }
      ]
    },
    {
      id: 'cycle',
      label: 'Personal Bike',
      detail: 'Cycle to Station',
      time: 17,
      cost: 0.00,
      distance: 3,
      riskScore: 1, // Cycle(+1)
      iconId: ICON_IDS.BIKE,
      color: 'text-blue-600',
      bgColor: 'bg-blue-100',
      lineColor: '#3b82f6',
      desc: 'Zero emissions.',
      segments: [
        { mode: 'bike', label: 'Bike', lineColor: '#3b82f6', iconId: ICON_IDS.BIKE, time: 17, to: 'Leeds Station' }
      ]
    }
  ],
  mainLeg: {
    id: 'train_main',
    label: 'CrossCountry',
    detail: 'Leeds → Loughborough',
    time: 102,
    cost: 25.70,
    distance: 80,
    riskScore: 1, // Train(+1)
    iconId: ICON_IDS.TRAIN,
    color: 'text-[#713e8d]',
    bgColor: 'bg-indigo-100',
    lineColor: '#713e8d',
    platform: 4,
    segments: [
      { mode: 'train', label: 'CrossCountry', lineColor: '#713e8d', iconId: ICON_IDS.TRAIN, time: 102, to: 'Loughborough Station' }
    ]
  },
  lastMile: [
    {
      id: 'uber',
      label: 'Uber',
      detail: 'Loughborough → East Leake',
      time: 10,
      cost: 14.89,
      distance: 5,
      riskScore: 0,
      iconId: ICON_IDS.CAR,
      color: 'text-black',
      bgColor: 'bg-zinc-100',
      lineColor: '#000000',
      desc: 'Reliable final leg.',
      segments: [
        { mode: 'taxi', label: 'Uber', lineColor: '#000000', iconId: ICON_IDS.CAR, time: 10, to: 'East Leake' }
      ]
    },
    {
      id: 'bus',
      label: 'Bus (Line 1)',
      detail: 'Walk 4min + Bus 10min',
      time: 14,
      cost: 3.00,
      distance: 5,
      riskScore: 2, // Bus Loughborough (+2)
      iconId: ICON_IDS.BUS,
      color: 'text-brand-dark',
      bgColor: 'bg-brand-light',
      lineColor: '#0f766e',
      recommended: true,
      desc: 'Short walk required.',
      segments: [
        { mode: 'bus', label: 'Bus', lineColor: '#0f766e', iconId: ICON_IDS.BUS, time: 14, to: 'East Leake' }
      ]
    },
    {
      id: 'cycle',
      label: 'Personal Bike',
      detail: 'Cycle to Dest',
      time: 24,
      cost: 0.00,
      distance: 5,
      riskScore: 1, // Cycle (+1)
      iconId: ICON_IDS.BIKE,
      color: 'text-blue-600',
      bgColor: 'bg-blue-100',
      lineColor: '#3b82f6',
      desc: 'Scenic route.',
      segments: [
        { mode: 'bike', label: 'Bike', lineColor: '#3b82f6', iconId: ICON_IDS.BIKE, time: 24, to: 'East Leake' }
      ]
    }
  ]
};

const DIRECT_DRIVE = {
  time: 110, // 1h 50m
  cost: 39.15, // 87 miles * 45p
  distance: 87
};

const MOCK_PATH = [
  [53.8008, -1.5491], // Leeds
  [52.7698, -1.2062]  // East Leake
];

const formatDuration = (minutes) => {
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  if (h === 0) return `${m} min`;
  return `${h}hr ${m}`;
};

const formatTimeRange = (startDate, durationMinutes) => {
  const end = new Date(startDate.getTime() + durationMinutes * 60000);
  return `${startDate.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })} - ${end.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`;
};

const getStationBuffer = () => {
  return 10;
};

const getLegEmission = (leg) => {
  let factor = 0;
  if (leg.iconId === ICON_IDS.TRAIN) factor = 0.06;
  else if (leg.iconId === ICON_IDS.BUS) factor = 0.10;
  else if (leg.iconId === ICON_IDS.CAR) factor = 0.27; // Taxi/Drive

  // Check specific IDs or segments for finer grain if needed, but icon is a good proxy for this demo
  // Or iterate segments
  let legDist = leg.distance || 0;

  // Simplification: Use leg total distance * primary mode factor
  return legDist * factor;
};

const calculateTotalStats = (leg1, leg3) => {
  const buffer = getStationBuffer(leg1.id);
  const cost = leg1.cost + SEGMENT_OPTIONS.mainLeg.cost + leg3.cost;
  const time = leg1.time + buffer + SEGMENT_OPTIONS.mainLeg.time + leg3.time;

  // Risk Score Calculation
  const risk = (leg1.riskScore || 0) + (SEGMENT_OPTIONS.mainLeg.riskScore || 0) + (leg3.riskScore || 0);

  // Emissions Calculation
  const carEmission = DIRECT_DRIVE.distance * 0.27; // kg CO2

  const totalEmission = getLegEmission(leg1) + getLegEmission(SEGMENT_OPTIONS.mainLeg) + getLegEmission(leg3);
  const savings = carEmission - totalEmission;
  const savingsPercent = Math.round((savings / carEmission) * 100);

  const emissions = {
      val: savings,
      percent: savingsPercent,
      text: savings > 0 ? `Saves ${savingsPercent}% CO₂ vs driving` : null
  };

  return { cost, time, buffer, risk, emissions };
};

const getAllCombinations = () => {
  const combos = [];
  SEGMENT_OPTIONS.firstMile.forEach(l1 => {
    SEGMENT_OPTIONS.lastMile.forEach(l3 => {
      const stats = calculateTotalStats(l1, l3);
      combos.push({
        id: `${l1.id}-${l3.id}`,
        leg1: l1,
        leg3: l3,
        ...stats
      });
    });
  });
  return combos;
};

const getTop3Results = (tab, selectedModes) => {
  let combos = getAllCombinations();

  // Filter based on selectedModes
  // selectedModes is expected to be an object like { train: true, bus: true, ... }
  if (selectedModes) {
      combos = combos.filter(combo => {
        const allSegments = [
          ...(combo.leg1.segments || []),
          ...(SEGMENT_OPTIONS.mainLeg.segments || []),
          ...(combo.leg3.segments || [])
        ];
        // Check if every segment in the journey is allowed by selectedModes
        return allSegments.every(seg => {
          if (seg.mode === 'walk') return true; // Always allow walking
          if (seg.mode === 'taxi') return selectedModes.taxi;
          return selectedModes[seg.mode];
        });
      });
  }

  if (tab === 'fastest') {
    return combos.sort((a, b) => a.time - b.time).slice(0, 3);
  } else if (tab === 'cheapest') {
    return combos.sort((a, b) => a.cost - b.cost).slice(0, 3);
  } else {
    // Smart: weighted score (Cost + 0.3 * Time)
    return combos.sort((a, b) => {
        const scoreA = a.cost + (a.time * 0.3);
        const scoreB = b.cost + (b.time * 0.3);
        return scoreA - scoreB;
    }).slice(0, 3);
  }
};

const getFlattenedSegments = (leg1, leg3) => {
  return [
    ...(leg1.segments || []),
    ...(SEGMENT_OPTIONS.mainLeg.segments || []),
    ...(leg3.segments || [])
  ];
};

module.exports = {
    SEGMENT_OPTIONS,
    DIRECT_DRIVE,
    MOCK_PATH,
    ICON_IDS,
    formatDuration,
    formatTimeRange,
    getStationBuffer,
    getLegEmission,
    calculateTotalStats,
    getAllCombinations,
    getTop3Results,
    getFlattenedSegments
};
