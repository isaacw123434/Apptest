import { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { MapContainer, TileLayer, Polyline, useMapEvents, useMap } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import {
  Train, Car, Bus, Bike, Clock,
  ChevronRight, ChevronLeft, ChevronDown,
  X, Zap, ShieldCheck, Leaf, Footprints,
  User, Shield, Heart
} from 'lucide-react';

// --- DATA CONSTANTS ---

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
      icon: Car,
      color: 'text-black',
      bgColor: 'bg-zinc-100',
      lineColor: '#000000',
      desc: 'Fastest door-to-door.',
      waitTime: 4,
      segments: [
        { mode: 'taxi', label: 'Uber', lineColor: '#000000', icon: Car, time: 14, to: 'Leeds Station' }
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
      icon: Bus,
      color: 'text-brand-dark', // updated color usage
      bgColor: 'bg-brand-light', // updated color usage
      lineColor: '#0f766e',
      recommended: true,
      desc: 'Best balance.',
      nextBusIn: 12,
      segments: [
        { mode: 'bus', label: 'Bus', lineColor: '#0f766e', icon: Bus, time: 23, to: 'Leeds Station' }
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
      icon: Car,
      color: 'text-zinc-800',
      bgColor: 'bg-zinc-100',
      lineColor: '#3f3f46',
      desc: 'Flexibility.',
      segments: [
        { mode: 'car', label: 'Drive', lineColor: '#3f3f46', icon: Car, time: 15, to: 'Leeds Station' }
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
      icon: Footprints,
      color: 'text-slate-600',
      bgColor: 'bg-slate-100',
      lineColor: '#1d4ed8',
      desc: 'Walking transfer.',
      segments: [
        { mode: 'walk', label: 'Walk', lineColor: '#475569', icon: Footprints, time: 18, to: 'Headingley Station' },
        { mode: 'train', label: 'Northern', lineColor: '#1d4ed8', icon: Train, time: 10, to: 'Leeds Station' }
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
      icon: Car,
      color: 'text-slate-600',
      bgColor: 'bg-slate-100',
      lineColor: '#1d4ed8',
      desc: 'Fast transfer.',
      waitTime: 3,
      segments: [
        { mode: 'taxi', label: 'Uber', lineColor: '#000000', icon: Car, time: 5, to: 'Headingley Station' },
        { mode: 'train', label: 'Northern', lineColor: '#1d4ed8', icon: Train, time: 10, to: 'Leeds Station' }
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
      icon: Bike,
      color: 'text-blue-600',
      bgColor: 'bg-blue-100',
      lineColor: '#3b82f6',
      desc: 'Zero emissions.',
      segments: [
        { mode: 'bike', label: 'Bike', lineColor: '#3b82f6', icon: Bike, time: 17, to: 'Leeds Station' }
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
    icon: Train,
    color: 'text-[#713e8d]',
    bgColor: 'bg-indigo-100',
    lineColor: '#713e8d',
    platform: 4,
    segments: [
      { mode: 'train', label: 'CrossCountry', lineColor: '#713e8d', icon: Train, time: 102, to: 'Loughborough Station' }
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
      icon: Car,
      color: 'text-black',
      bgColor: 'bg-zinc-100',
      lineColor: '#000000',
      desc: 'Reliable final leg.',
      segments: [
        { mode: 'taxi', label: 'Uber', lineColor: '#000000', icon: Car, time: 10, to: 'East Leake' }
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
      icon: Bus,
      color: 'text-brand-dark',
      bgColor: 'bg-brand-light',
      lineColor: '#0f766e',
      recommended: true,
      desc: 'Short walk required.',
      segments: [
        { mode: 'bus', label: 'Bus', lineColor: '#0f766e', icon: Bus, time: 14, to: 'East Leake' }
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
      icon: Bike,
      color: 'text-blue-600',
      bgColor: 'bg-blue-100',
      lineColor: '#3b82f6',
      desc: 'Scenic route.',
      segments: [
        { mode: 'bike', label: 'Bike', lineColor: '#3b82f6', icon: Bike, time: 24, to: 'East Leake' }
      ]
    }
  ]
};

const DIRECT_DRIVE = {
  time: 110,
  cost: 39.15,
  distance: 87
};

const MOCK_PATH = [
  [53.8008, -1.5491], // Leeds
  [52.7698, -1.2062]  // East Leake
];

// --- SUB-COMPONENTS ---

const ModeIcon = ({ icon: Icon, className = "" }) => (
  <div className={`p-2 rounded-xl shadow-sm ${className}`}>
    <Icon size={20} />
  </div>
);

ModeIcon.propTypes = {
  icon: PropTypes.elementType.isRequired,
  className: PropTypes.string,
};

const SwapModal = ({ isOpen, onClose, title, options, onSelect, currentId }) => {
  if (!isOpen) return null;
  return (
    <div className="fixed inset-0 z-[60] flex items-end sm:items-center justify-center bg-black/40 backdrop-blur-[2px] p-0 sm:p-4 animate-in fade-in duration-200">
      <div className="bg-white w-full max-w-md sm:rounded-2xl rounded-t-2xl shadow-2xl overflow-hidden animate-in slide-in-from-bottom-10 duration-300">
        <div className="p-4 border-b flex justify-between items-center bg-slate-50">
          <h3 className="font-semibold text-lg text-slate-800">{title}</h3>
          <button onClick={onClose} className="p-2 hover:bg-slate-200 rounded-full transition-colors">
            <X size={20} />
          </button>
        </div>
        <div className="p-4 space-y-3 max-h-[60vh] overflow-y-auto">
          {options.map((opt) => (
            <button
              key={opt.id}
              onClick={() => { onSelect(opt); onClose(); }}
              className={`w-full text-left p-4 rounded-xl border transition-all duration-200 flex items-center gap-4
                ${currentId === opt.id
                  ? 'border-accent bg-blue-50 ring-1 ring-accent'
                  : 'border-slate-100 hover:border-blue-200 hover:bg-slate-50 shadow-sm'
                }`}
            >
              <ModeIcon icon={opt.icon} className={currentId === opt.id ? "bg-blue-200 text-accent" : "bg-slate-100 text-slate-600"} />
              <div className="flex-1">
                <div className="flex justify-between items-center mb-1">
                  <span className="font-semibold text-slate-900">{opt.label}</span>
                  <span className="font-bold text-slate-900">£{opt.cost.toFixed(2)}</span>
                </div>
                <div className="flex justify-between text-sm text-slate-500">
                  <span>{opt.time} min</span>
                  {opt.recommended && <span className="text-brand-dark font-medium text-xs bg-brand-light px-2 py-0.5 rounded-full">Best Value</span>}
                </div>
              </div>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
};

SwapModal.propTypes = {
  isOpen: PropTypes.bool.isRequired,
  onClose: PropTypes.func.isRequired,
  title: PropTypes.string.isRequired,
  options: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.string.isRequired,
    label: PropTypes.string.isRequired,
    detail: PropTypes.string,
    time: PropTypes.number.isRequired,
    cost: PropTypes.number.isRequired,
    icon: PropTypes.elementType.isRequired,
    color: PropTypes.string,
    bgColor: PropTypes.string,
    lineColor: PropTypes.string,
    desc: PropTypes.string,
    recommended: PropTypes.bool,
  })).isRequired,
  onSelect: PropTypes.func.isRequired,
  currentId: PropTypes.string.isRequired,
};

// --- LOGIC HELPERS ---

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
  if (leg.icon === Train) factor = 0.06;
  else if (leg.icon === Bus) factor = 0.10;
  else if (leg.icon === Car) factor = 0.27; // Taxi/Drive

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

  // Filter based on selected modes
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

// --- MAP COMPONENTS ---

const MapClickHandler = ({ onClick }) => {
  useMapEvents({
    click: onClick,
  });
  return null;
};

MapClickHandler.propTypes = {
  onClick: PropTypes.func.isRequired,
};

const FitBoundsToView = ({ bounds, paddingBottom }) => {
  const map = useMap();
  useEffect(() => {
    if (bounds) {
      map.fitBounds(bounds, {
        paddingBottomRight: [0, paddingBottom],
        paddingTopLeft: [20, 20]
      });
    }
  }, [bounds, map, paddingBottom]);
  return null;
};

FitBoundsToView.propTypes = {
  bounds: PropTypes.arrayOf(PropTypes.arrayOf(PropTypes.number)).isRequired,
  paddingBottom: PropTypes.number.isRequired,
};

const getFlattenedSegments = (leg1, leg3) => {
  return [
    ...(leg1.segments || []),
    ...(SEGMENT_OPTIONS.mainLeg.segments || []),
    ...(leg3.segments || [])
  ];
};

// 1. SCHEMATIC (For Summary View)
const SchematicMap = ({ leg1, leg3 }) => {
  const segments = getFlattenedSegments(leg1, leg3);
  const totalWidth = 300; // 350 - 50
  const startX = 50;
  const segmentWidth = totalWidth / segments.length;
  const y = 60;

  return (
    <div className="relative h-full w-full bg-slate-50 overflow-hidden">
      <div className="absolute inset-0 opacity-30" style={{backgroundImage: 'radial-gradient(#94a3b8 1px, transparent 1px)', backgroundSize: '16px 16px'}} />
      <svg className="w-full h-full" viewBox="0 0 400 120" preserveAspectRatio="xMidYMid meet">
        {/* Base Track */}
        <line x1="50" y1={y} x2="350" y2={y} className="stroke-slate-200" strokeWidth="4" />

        {/* Active Route Segments */}
        {segments.map((seg, i) => {
           const x1 = startX + i * segmentWidth;
           const x2 = x1 + segmentWidth;
           return (
             <g key={i}>
               <line x1={x1} y1={y} x2={x2} y2={y} stroke={seg.lineColor} strokeWidth="4" strokeLinecap="round" className="transition-colors duration-500" />
               <text x={x1 + segmentWidth/2} y={i % 2 === 0 ? y + 25 : y - 15} textAnchor="middle" className="text-[10px] fill-slate-500 font-medium">{seg.label}</text>
             </g>
           );
         })}

        {/* Nodes */}
        <circle cx={startX} cy={y} r="4" className="fill-white stroke-slate-500 stroke-2" />
        <text x={startX} y={y + 35} textAnchor="middle" className="text-[10px] fill-slate-500 font-bold uppercase tracking-wider">Start</text>

        {segments.map((seg, i) => {
           const cx = startX + (i + 1) * segmentWidth;
           const isLast = i === segments.length - 1;
           return (
             <g key={i}>
               <circle cx={cx} cy={y} r={isLast ? 4 : 6} className={isLast ? "fill-slate-800 stroke-white stroke-2" : "fill-white stroke-2"} stroke={isLast ? "white" : seg.lineColor} />
               <text x={cx} y={isLast ? y + 35 : y - 15} textAnchor="middle" className="text-[10px] font-bold uppercase tracking-wider" fill={isLast ? "black" : seg.lineColor}>
                 {isLast ? "End" : (seg.to ? seg.to.replace(' Stn', '') : "Node")}
               </text>
             </g>
           );
         })}
      </svg>
    </div>
  );
};

SchematicMap.propTypes = {
  leg1: PropTypes.shape({
    id: PropTypes.string.isRequired,
    label: PropTypes.string.isRequired,
    lineColor: PropTypes.string.isRequired,
  }).isRequired,
  leg3: PropTypes.shape({
    id: PropTypes.string.isRequired,
    label: PropTypes.string.isRequired,
    lineColor: PropTypes.string.isRequired,
  }).isRequired,
};

// 3. TIMELINE SCHEMATIC (Replaces MiniSchematic)
const TimelineSchematic = ({ leg1, leg3, startTime }) => {
  const mainLeg = SEGMENT_OPTIONS.mainLeg;

  // Flatten segments and inherit properties
  const allSegments = [
    ...(leg1.segments || []).map(s => ({ ...s, bgColor: leg1.bgColor, color: leg1.color })),
    ...(mainLeg.segments || []).map(s => ({ ...s, bgColor: mainLeg.bgColor, color: mainLeg.color, isMain: true })),
    ...(leg3.segments || []).map(s => ({ ...s, bgColor: leg3.bgColor, color: leg3.color }))
  ];

  const totalDuration = allSegments.reduce((acc, seg) => acc + seg.time, 0);

  // Time Calculation for Text Description
  let currentTime = new Date(startTime);

  const routeTextParts = allSegments.map((seg) => {
    const startStr = currentTime.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: false });
    const durationStr = formatDuration(seg.time);

    // Advance time
    currentTime = new Date(currentTime.getTime() + seg.time * 60000);

    // Simplify Label
    let label = seg.label;
    if (seg.mode === 'bus') label = 'Bus';
    if (seg.mode === 'train') label = 'Train';
    if (seg.mode === 'taxi') label = 'Uber';
    if (seg.mode === 'walk') label = 'Walk';

    return `${startStr} ${label} (${durationStr})`;
  });

  return (
    <div className="w-full flex flex-col gap-2">
      {/* Visual Timeline */}
      <div className="flex w-full h-10 overflow-hidden">
        {allSegments.map((seg, index) => {
          const width = (seg.time / totalDuration) * 100;
          const isMain = seg.isMain;
          const isFirst = index === 0;
          const isLast = index === allSegments.length - 1;

          let backgroundColor;
          let textColorClass = seg.color;
          let bgClass = seg.bgColor;

          if (isMain) {
            backgroundColor = seg.lineColor;
            textColorClass = 'text-white';
            bgClass = '';
          } else if (seg.label === 'Uber' || seg.mode === 'taxi') {
            backgroundColor = '#000000';
            textColorClass = 'text-white';
            bgClass = '';
          } else if (seg.label === 'Northern') {
            backgroundColor = seg.lineColor;
            textColorClass = 'text-white';
            bgClass = '';
          }

          return (
            <div
              key={index}
              style={{
                width: `${width}%`,
                minWidth: 'max-content',
                zIndex: allSegments.length - index,
                backgroundColor: backgroundColor,
                paddingLeft: isFirst ? '8px' : '20px',
                paddingRight: '8px'
              }}
              className={`
                flex items-center justify-center gap-1 relative h-full shrink
                rounded-r-xl ${isFirst ? 'rounded-l-xl' : '-ml-3'}
                ${!isLast ? 'border-r-2 border-white' : ''}
                ${bgClass}
                ${textColorClass}
              `}
            >
               <seg.icon size={16} />
               <span className="text-[10px] font-bold whitespace-nowrap">{isMain ? 'CrossCountry' : seg.label.split(' ')[0]}</span>
            </div>
          );
        })}
      </div>

      {/* Route Text Description */}
      <div className="flex items-center justify-center text-[11px] font-medium text-slate-900 bg-white/50 py-1 rounded-lg flex-wrap gap-y-1">
        {routeTextParts.map((part, i) => (
          <span key={i} className="flex items-center whitespace-nowrap">
            {part}
            {i < routeTextParts.length - 1 && <ChevronRight size={12} className="mx-1 text-slate-400" />}
          </span>
        ))}
      </div>
    </div>
  );
};

TimelineSchematic.propTypes = {
  leg1: PropTypes.shape({
    id: PropTypes.string,
    label: PropTypes.string.isRequired,
    time: PropTypes.number.isRequired,
    bgColor: PropTypes.string,
    color: PropTypes.string,
    lineColor: PropTypes.string,
    icon: PropTypes.elementType.isRequired,
    segments: PropTypes.arrayOf(PropTypes.shape({
      mode: PropTypes.string.isRequired,
      label: PropTypes.string.isRequired,
      time: PropTypes.number.isRequired,
      lineColor: PropTypes.string.isRequired,
      icon: PropTypes.elementType.isRequired,
      to: PropTypes.string,
    })),
  }).isRequired,
  leg3: PropTypes.shape({
    id: PropTypes.string,
    label: PropTypes.string.isRequired,
    time: PropTypes.number.isRequired,
    bgColor: PropTypes.string,
    color: PropTypes.string,
    lineColor: PropTypes.string,
    icon: PropTypes.elementType.isRequired,
    segments: PropTypes.arrayOf(PropTypes.shape({
      mode: PropTypes.string.isRequired,
      label: PropTypes.string.isRequired,
      time: PropTypes.number.isRequired,
      lineColor: PropTypes.string.isRequired,
      icon: PropTypes.elementType.isRequired,
      to: PropTypes.string,
    })),
  }).isRequired,
  startTime: PropTypes.instanceOf(Date).isRequired,
};

// 2. REALISTIC MAP (For Detail View)
const RealisticMap = ({ leg1, leg3, focusedSegment }) => {
  const getViewBox = () => {
    if (focusedSegment === 'first') return "20 120 160 80"; // Zoom Leeds
    if (focusedSegment === 'last') return "220 20 160 80"; // Zoom Loughborough
    return "0 0 400 220"; // Full View
  };

  return (
    <div className="relative w-full h-full bg-[#e5e7eb] overflow-hidden">
      <svg className="w-full h-full transition-all duration-700 ease-in-out" viewBox={getViewBox()} preserveAspectRatio="xMidYMid slice">
        {/* Land & Water */}
        <rect width="400" height="220" fill="#f3f4f6" />
        <path d="M-10,180 Q100,160 150,130 T410,140" fill="none" stroke="#bfdbfe" strokeWidth="15" />
        <path d="M40,140 L80,140 L90,170 L30,180 Z" fill="#dcfce7" /> {/* Park */}
        <path d="M280,40 L350,30 L360,70 L300,80 Z" fill="#dcfce7" /> {/* Park */}

        {/* Roads */}
        <g stroke="white" strokeWidth="4" fill="none">
          <path d="M0,200 L400,100" />
          <path d="M50,0 L100,220" />
          <path d="M300,0 L350,220" />
        </g>

        {/* Routes */}
        <path d="M50,160 Q80,160 140,110" fill="none" stroke={leg1.lineColor} strokeWidth="4" strokeLinecap="round" strokeDasharray={leg1.id === 'bus' ? '0' : '3 3'} />
        <path d="M140,110 Q240,110 340,60" fill="none" stroke="#4f46e5" strokeWidth="4" strokeDasharray="6 4" className="opacity-60" />
        <path d="M340,60 Q360,60 380,30" fill="none" stroke={leg3.lineColor} strokeWidth="4" strokeLinecap="round" />

        {/* Markers */}
        <circle cx="50" cy="160" r="3" fill="white" stroke="#64748b" strokeWidth="2" />
        <circle cx="140" cy="110" r="4" fill="white" stroke="#4f46e5" strokeWidth="2" />
        <circle cx="340" cy="60" r="4" fill="white" stroke="#4f46e5" strokeWidth="2" />
        <circle cx="380" cy="30" r="3" fill="#1e293b" stroke="white" strokeWidth="1" />
      </svg>
      {focusedSegment && (
        <div className="absolute top-4 left-4 bg-white/90 backdrop-blur px-3 py-1.5 rounded-lg shadow-sm text-xs font-bold text-slate-700 animate-in fade-in">
          {focusedSegment === 'first' ? 'Zoom: Leeds Area' : 'Zoom: Loughborough Area'}
        </div>
      )}
    </div>
  );
};

RealisticMap.propTypes = {
  leg1: PropTypes.shape({
    id: PropTypes.string.isRequired,
    lineColor: PropTypes.string.isRequired,
  }).isRequired,
  leg3: PropTypes.shape({
    id: PropTypes.string.isRequired,
    lineColor: PropTypes.string.isRequired,
  }).isRequired,
  focusedSegment: PropTypes.string,
};

// --- MAIN APP ---

export default function JourneyPlanner() {
  const [view, setView] = useState('summary'); // 'summary' or 'detail'

  useEffect(() => {
    const handlePopState = (event) => {
      if (event.state && event.state.view === 'detail') {
        setView('detail');
      } else {
        setView('summary');
      }
    };
    window.addEventListener('popstate', handlePopState);
    return () => window.removeEventListener('popstate', handlePopState);
  }, []);

  const goToDetail = () => {
    window.history.pushState({ view: 'detail' }, '', '#detail');
    setView('detail');
  };

  const goToSummary = () => {
    if (view === 'detail') {
       window.history.back();
    } else {
       setView('summary');
    }
  };

  const [activeTab, setActiveTab] = useState('smart'); // fastest, cheapest, smart

  const [isModeDropdownOpen, setIsModeDropdownOpen] = useState(false);
  const [selectedModes, setSelectedModes] = useState({
    train: true, bus: true, car: true, bike: false, taxi: true
  });

  // Journey State
  const [journeyConfig, setJourneyConfig] = useState({
    leg1: SEGMENT_OPTIONS.firstMile.find(o => o.id === 'bus'),
    leg3: SEGMENT_OPTIONS.lastMile.find(o => o.id === 'uber')
  });

  const [showSwap, setShowSwap] = useState(null); // 'first' or 'last'
  const [sheetHeight, setSheetHeight] = useState(35);
  const [isDragging, setIsDragging] = useState(false);

  const handleDragStart = () => {
    setIsDragging(true);
  };

  const handleDragMove = (e) => {
    if (!isDragging) return;
    const clientY = e.touches ? e.touches[0].clientY : e.clientY;
    const windowHeight = window.innerHeight;
    const newHeight = ((windowHeight - clientY) / windowHeight) * 100;
    if (newHeight > 20 && newHeight < 90) {
      setSheetHeight(newHeight);
    }
  };

  const handleDragEnd = () => {
    setIsDragging(false);
    // Snap to positions
    if (sheetHeight > 50) setSheetHeight(85);
    else setSheetHeight(25);
  };

  // Derived Calculations for Detail View
  const buffer = getStationBuffer(journeyConfig.leg1.id);
  const totalCost = journeyConfig.leg1.cost + SEGMENT_OPTIONS.mainLeg.cost + journeyConfig.leg3.cost;
  const totalTime = journeyConfig.leg1.time + buffer + SEGMENT_OPTIONS.mainLeg.time + journeyConfig.leg3.time;

  const totalEmission = getLegEmission(journeyConfig.leg1) + getLegEmission(SEGMENT_OPTIONS.mainLeg) + getLegEmission(journeyConfig.leg3);

  const departureDate = new Date();
  departureDate.setHours(7, 10, 0, 0);
  const leaveHomeTime = new Date(departureDate.getTime());

  const formatTime = (date) => date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

  const journeyLegs = [
    { type: 'first', data: journeyConfig.leg1, onSwap: () => setShowSwap('first') },
    { type: 'main', data: SEGMENT_OPTIONS.mainLeg, onSwap: null },
    { type: 'last', data: journeyConfig.leg3, onSwap: () => setShowSwap('last') }
  ];
  let currentDateTime = new Date(leaveHomeTime);

  // --- VIEW 1: SUMMARY PAGE ---
  if (view === 'summary') {
    const topResults = getTop3Results(activeTab, selectedModes);
    // Find min risk for "Least Risky" badge
    const minRisk = Math.min(...topResults.map(r => r.risk));

    return (
      <div className="flex flex-col h-screen bg-slate-50 font-sans text-slate-900">

        {/* New Header */}
        <header className="bg-brand text-white p-4 shadow-md flex justify-between items-center z-20">
            <h1 className="text-xl font-bold tracking-tight">EndMile Routing</h1>
            <div className="bg-brand-dark p-2 rounded-full">
                <User size={20} className="text-brand-light" />
            </div>
        </header>

        {/* Search Box */}
        <div className="bg-white p-4 shadow-sm z-10">
          <div className="flex flex-col gap-3">
             <div className="flex items-center gap-2 bg-slate-100 p-3 rounded-xl">
               <div className="w-2 h-2 rounded-full bg-slate-400"></div>
               <input type="text" defaultValue="St Chads, Leeds" className="bg-transparent font-medium text-slate-700 w-full outline-none" />
             </div>
             <div className="flex items-center gap-2 bg-slate-100 p-3 rounded-xl">
               <div className="w-2 h-2 rounded-full bg-slate-800"></div>
               <input type="text" defaultValue="East Leake, Loughborough" className="bg-transparent font-medium text-slate-700 w-full outline-none" />
             </div>

             <div className="flex gap-2">
                <div className="flex items-center bg-slate-100 rounded-xl px-3 py-2 flex-1 relative min-w-0">
                   <select className="bg-transparent text-[10px] font-bold text-slate-500 outline-none appearance-none pr-4 cursor-pointer">
                      <option>Depart</option>
                      <option>Arrive</option>
                   </select>
                   <ChevronDown size={10} className="absolute left-[3.2rem] top-1/2 -translate-y-1/2 pointer-events-none text-slate-400" />
                   <input type="time" defaultValue="09:00" className="bg-transparent text-sm font-bold text-slate-900 outline-none ml-2 w-full min-w-0" />
                </div>
                <button className="bg-brand hover:bg-brand-dark text-white font-bold py-3 px-8 rounded-xl shadow-md transition-colors">
                  Search
                </button>
             </div>

             {/* Mode Selection Dropdown Trigger */}
             <button
                onClick={() => setIsModeDropdownOpen(!isModeDropdownOpen)}
                className="flex items-center justify-between px-2 py-1 text-sm font-medium text-slate-500 hover:text-slate-700 transition-colors"
             >
                <span>Filter Modes</span>
                <ChevronDown size={16} className={`transition-transform ${isModeDropdownOpen ? 'rotate-180' : ''}`} />
             </button>

             {/* Dropdown Content */}
             {isModeDropdownOpen && (
                <div className="grid grid-cols-5 gap-2 animate-in slide-in-from-top-2 duration-200">
                    {[
                        { id: 'train', icon: Train, label: 'Train' },
                        { id: 'bus', icon: Bus, label: 'Bus' },
                        { id: 'car', icon: Car, label: 'Car' },
                        { id: 'taxi', icon: Car, label: 'Taxi' },
                        { id: 'bike', icon: Bike, label: 'Bike' },
                    ].map(mode => (
                        <button
                            key={mode.id}
                            onClick={() => setSelectedModes(prev => ({...prev, [mode.id]: !prev[mode.id]}))}
                            className={`flex flex-col items-center gap-1 p-2 rounded-xl border transition-all
                                ${selectedModes[mode.id]
                                    ? 'bg-blue-50 border-accent text-accent'
                                    : 'bg-white border-slate-200 text-slate-400 grayscale'
                                }`}
                        >
                            <mode.icon size={20} />
                            <span className="text-[10px] font-bold">{mode.label}</span>
                        </button>
                    ))}
                </div>
             )}
          </div>
        </div>

        {/* Tabs */}
        <div className="bg-white flex border-b border-slate-100 mt-2">
          {[
            { id: 'fastest', label: 'Fastest', icon: Zap },
            { id: 'smart', label: 'Best Value', icon: ShieldCheck },
            { id: 'cheapest', label: 'Cheapest', icon: Leaf },
          ].map(tab => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`flex-1 py-4 text-sm font-medium flex flex-col items-center justify-center gap-1 transition-colors border-b-2
                ${activeTab === tab.id
                  ? 'border-brand text-brand bg-brand-light/30'
                  : 'border-transparent text-slate-400 hover:text-slate-600'}`}
            >
              <tab.icon size={18} />
              {tab.label}
            </button>
          ))}
        </div>

        {/* Main Content: Results List */}
        <div className="p-4 space-y-4 overflow-y-auto pb-20 bg-slate-50 flex-1">
           {topResults.map((result, index) => (
             <div
               key={index}
               onClick={() => {
                 setJourneyConfig({ leg1: result.leg1, leg3: result.leg3 });
                 goToDetail();
               }}
               className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden cursor-pointer hover:shadow-md transition-all active:scale-[0.98]"
             >
                <div className="p-4">
                  <div className="flex justify-between items-center mb-4">
                     <div>
                       <h3 className="text-2xl font-bold text-slate-900">£{result.cost.toFixed(2)}</h3>
                       <div className="flex items-center gap-2 text-slate-500 text-xs font-medium">
                         {result.buffer > 0 && <span className="text-slate-400">incl. {result.buffer}m wait</span>}
                       </div>
                     </div>
                     <div className="flex flex-col items-end text-right">
                        <div className="text-xl font-bold text-slate-900">{formatDuration(result.time)}</div>
                        <div className="text-xs text-slate-500 font-medium">
                          {formatTimeRange(departureDate, result.time)}
                        </div>
                     </div>
                  </div>

                  {/* Timeline Schematic */}
                  <div className="mb-3">
                    <TimelineSchematic leg1={result.leg1} leg3={result.leg3} startTime={departureDate} />
                  </div>

                  {/* Badges: Risk & Emissions */}
                  <div className="flex items-center gap-2 mb-2">
                    {/* Risk Badge */}
                    {result.risk === minRisk && (
                        <div className="flex items-center gap-1 bg-blue-50 text-blue-700 px-2 py-1 rounded-md text-[10px] font-bold border border-blue-100">
                            <Shield size={12} />
                            <span>Least Risky</span>
                        </div>
                    )}
                    {/* Emissions Badge */}
                    {result.emissions.text && (
                        <div className="flex items-center gap-1 bg-emerald-50 text-emerald-700 px-2 py-1 rounded-md text-[10px] font-bold border border-emerald-100">
                            <Leaf size={12} />
                            <span>{result.emissions.text}</span>
                        </div>
                    )}
                  </div>

                  <div className="flex justify-between items-center text-xs text-slate-400">
                    <span></span>
                    <ChevronRight size={16} />
                  </div>
                </div>
                {index === 0 && (
                   <div className="bg-emerald-50 text-emerald-700 text-[10px] font-bold text-center py-1 uppercase tracking-wide">
                     Top Choice
                   </div>
                )}
             </div>
           ))}
           <div className="mt-8 text-center px-8">
            <p className="text-xs text-slate-400">
              vs Direct Drive: <span className="line-through decoration-red-400 decoration-2 font-semibold">£{DIRECT_DRIVE.cost.toFixed(2)}</span>
            </p>
           </div>
        </div>
      </div>
    );
  }

  // --- VIEW 2: DETAIL & EDIT (Map + Slide Over) ---
  return (
    <div className="h-screen bg-slate-900 font-sans text-slate-900 flex flex-col overflow-hidden relative">

      {/* 1. MAP BACKGROUND */}
      <div className="absolute inset-0 z-0">
        <MapContainer
          bounds={MOCK_PATH}
          style={{ width: "100%", height: "100%" }}
          zoomControl={false}
        >
          <MapClickHandler onClick={() => setSheetHeight(10)} />
          <FitBoundsToView bounds={MOCK_PATH} paddingBottom={window.innerHeight * 0.35} />
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />
          <Polyline positions={MOCK_PATH} color="#3b82f6" weight={4} opacity={0.6} />
        </MapContainer>

        {/* Navigation Control */}
        <div className="absolute top-6 left-6 z-[1000]">
          <button
            onClick={goToSummary}
            className="bg-white px-4 py-2 rounded-full shadow-lg hover:bg-slate-50 transition-colors flex items-center gap-2 text-sm font-bold text-slate-700"
          >
            <ChevronLeft size={16} /> Back
          </button>
        </div>
      </div>

      {/* 2. SLIDING SHEET OVERLAY */}
      <div
        className="absolute inset-x-0 bottom-0 bg-white rounded-t-3xl shadow-[0_-10px_40px_rgba(0,0,0,0.2)] flex flex-col z-10"
        style={{
          height: `${sheetHeight}vh`,
          transition: isDragging ? 'none' : 'height 0.3s cubic-bezier(0.2, 0.8, 0.2, 1)'
        }}
      >

        {/* Handle */}
        <div
          className="w-full flex justify-center pt-3 pb-1 cursor-grab active:cursor-grabbing touch-none"
          onMouseDown={handleDragStart}
          onTouchStart={handleDragStart}
          onMouseMove={handleDragMove}
          onTouchMove={handleDragMove}
          onMouseUp={handleDragEnd}
          onTouchEnd={handleDragEnd}
          onMouseLeave={handleDragEnd}
        >
          <div className="w-12 h-1.5 bg-slate-200 rounded-full"></div>
        </div>


        {/* Sheet Header */}
        <div className="px-6 py-4 border-b border-slate-50 shrink-0 flex justify-between items-end group">
           <div>
             <h2 className="text-2xl font-bold text-slate-900">£{totalCost.toFixed(2)}</h2>
             <div className="flex items-center gap-2 text-sm text-slate-500">
               <Clock size={14} /> {Math.floor(totalTime / 60)}h {totalTime % 60}m
             </div>
           </div>
           <div className="flex flex-col items-end gap-1">
              <div className="flex items-center gap-2">
                 <button className="opacity-0 group-hover:opacity-100 transition-opacity p-2 hover:bg-slate-100 rounded-full text-slate-400 hover:text-red-500" title="Save Route">
                    <Heart size={20} />
                 </button>
                 <span className="text-xs font-semibold text-emerald-600 bg-emerald-50 px-2 py-1 rounded-md flex items-center gap-1">
                    <Leaf size={12} />
                    {totalEmission.toFixed(2)} kg CO₂
                 </span>
              </div>
           </div>
        </div>

        {/* DETAILED TIMELINE (Copied from previous "First Page" logic) */}
        <div className="flex-1 overflow-y-auto px-6 py-6 custom-scrollbar pb-24">
          <div className="relative pl-4 space-y-0">
            {/* Timeline Vertical Bar REMOVED */}
            {/* <div className="absolute left-[27px] top-4 bottom-4 w-0.5 bg-slate-200 rounded-full"></div> */}

            {/* 1. START TIME */}
            <div className="flex gap-3 min-h-[40px]">
              <div className="w-[4.5rem] text-right text-xs text-slate-500 font-mono py-1">{formatTime(leaveHomeTime)}</div>
              <div className="flex flex-col items-center z-10 w-4 relative">
                <div className="w-3 h-3 rounded-full bg-white border-2 border-slate-500 z-20"></div>
                <div className="absolute top-[6px] bottom-0 w-[3px]" style={{backgroundColor: journeyConfig.leg1.lineColor}}></div>
              </div>
              <div className="pb-6"><div className="text-sm font-semibold text-slate-700">Start Journey</div></div>
            </div>

            {journeyLegs.map((leg, legIndex) => {
              // Apply buffer before the main leg (Leeds station)
              if (legIndex === 1) {
                const buffer = getStationBuffer(journeyConfig.leg1.id);
                currentDateTime = new Date(currentDateTime.getTime() + buffer * 60000);
              }

              const segments = leg.data.segments || [];
              return (
                <div key={legIndex} className={leg.onSwap ? "group cursor-pointer" : ""}>
                   {segments.map((segment, segIndex) => {
                      const isLastSegmentInLeg = segIndex === segments.length - 1;
                      const isLastLeg = legIndex === journeyLegs.length - 1;

                      currentDateTime = new Date(currentDateTime.getTime() + segment.time * 60000);

                      return (
                        <div key={segIndex}>
                           {/* SEGMENT ROW */}
                           <div className="flex gap-3 group-hover:bg-slate-50 rounded-lg transition-all duration-200 -ml-2 p-2" onClick={leg.onSwap}>
                              {/* Time Column */}
                              <div className="w-[4.5rem] text-right pt-1 shrink-0">
                                <div className="text-base font-bold text-slate-800">{formatDuration(segment.time)}</div>
                              </div>

                              {/* Line Column */}
                              <div className="flex flex-col items-center z-10 w-4 relative shrink-0">
                                 <div className="absolute -top-2 -bottom-2 w-[3px]" style={{backgroundColor: segment.lineColor}}></div>
                              </div>

                              {/* Content Column */}
                              <div className="flex-1 pb-4 min-w-0">
                                  <div className="flex justify-between items-start mb-1 gap-2 flex-wrap">
                                     <div className="flex items-center gap-2 min-w-0">
                                       <ModeIcon icon={segment.icon} className="p-1 shrink-0" />
                                       <span className="text-lg font-bold text-slate-900">{segment.label}</span>
                                     </div>
                                     {segIndex === 0 && <span className="text-lg font-bold text-slate-900 shrink-0">£{leg.data.cost.toFixed(2)}</span>}
                                  </div>

                                  <div className="flex flex-col gap-1 mt-1">
                                    <span className="text-sm font-medium text-slate-600">{segment.to ? `To ${segment.to}` : segment.detail}</span>

                                    {/* Extra Info (Wait time, Platform, etc.) */}
                                    {(leg.data.waitTime && segment.mode === 'taxi') && (
                                       <span className="text-sm font-medium text-amber-600">Est wait: {leg.data.waitTime} min</span>
                                    )}
                                    {(leg.data.nextBusIn && segment.mode === 'bus') && (
                                       <span className="text-sm font-medium text-emerald-600">Next bus in {leg.data.nextBusIn} min</span>
                                    )}
                                    {(leg.data.platform && segment.mode === 'train') && (
                                       <span className="text-sm font-medium text-indigo-600">Est Platform: {leg.data.platform}</span>
                                    )}

                                    {/* Carbon Emission */}
                                    {(() => {
                                        const segmentDist = (segment.time / (leg.data.time || 1)) * (leg.data.distance || 0);
                                        const emission = getLegEmission({ ...segment, distance: segmentDist });
                                        if (emission > 0) {
                                            return <span className="text-sm text-slate-500">Carbon: {emission.toFixed(2)} kg CO₂</span>;
                                        }
                                        return null;
                                    })()}

                                    {leg.onSwap && segIndex === 0 && <span className="text-sm font-bold text-blue-600 hover:text-blue-700 transition-colors cursor-pointer mt-1">Edit Route</span>}
                                  </div>

                                  {/* BOOK NOW BUTTON */}
                                  {segment.mode === 'train' && (
                                    <div className="mt-4">
                                      <button
                                        onClick={(e) => { e.stopPropagation(); alert('Booking flow...'); }}
                                        className="w-full bg-brand hover:bg-brand-dark text-white font-bold py-2 px-4 rounded-lg shadow-sm transition-colors text-sm"
                                      >
                                        Book Now
                                      </button>
                                    </div>
                                  )}
                              </div>
                           </div>

                           {/* NODE ROW (End of Segment) */}
                           {(!isLastLeg || !isLastSegmentInLeg) && (
                              <div className="flex gap-3 min-h-[30px]">
                                <div className="w-[4.5rem] text-right text-xs text-slate-500 font-mono">{formatTime(currentDateTime)}</div>
                                <div className="flex flex-col items-center z-10 w-4 relative">
                                  {/* Line continues from top */}
                                  <div className="absolute top-0 h-[50%] w-[3px]" style={{backgroundColor: segment.lineColor}}></div>
                                  {/* Node */}
                                  <div className="w-2 h-2 rounded-full border-2 bg-white z-20" style={{borderColor: segment.lineColor}}></div>
                                  {/* Line continues to bottom */}
                                  <div className="absolute top-[50%] bottom-0 w-[3px]"
                                     style={{backgroundColor:
                                       isLastSegmentInLeg
                                         ? (journeyLegs[legIndex+1]?.data.segments[0].lineColor || segment.lineColor)
                                         : segments[segIndex+1].lineColor
                                     }}>
                                  </div>
                                </div>
                                <div className="pb-4 pt-0">
                                   <div className="text-xs font-medium text-slate-400 uppercase">
                                     {segment.to ? segment.to.replace(' Stn', '') : 'Transfer'}
                                   </div>
                                </div>
                              </div>
                           )}
                        </div>
                      );
                   })}
                </div>
              );
            })}

            {/* 6. ARRIVAL */}
            <div className="flex gap-3 min-h-[40px]">
              <div className="w-[4.5rem] text-right text-xs text-slate-500 font-mono py-1">{formatTime(currentDateTime)}</div>
              <div className="flex flex-col items-center z-10 w-4 relative">
                <div className="absolute top-0 h-[6px] w-[3px]" style={{backgroundColor: journeyConfig.leg3.lineColor}}></div>
                <div className="w-3 h-3 rounded-full bg-slate-800 z-20"></div>
              </div>
              <div><div className="text-sm font-semibold text-slate-700">Arrive East Leake</div></div>
            </div>
          </div>
        </div>

      </div>

      {/* MODALS */}
      <SwapModal
        isOpen={showSwap === 'first'} onClose={() => setShowSwap(null)}
        title="Change Start (Leeds)" options={SEGMENT_OPTIONS.firstMile}
        onSelect={(opt) => setJourneyConfig(prev => ({ ...prev, leg1: opt }))}
        currentId={journeyConfig.leg1.id}
      />
      <SwapModal
        isOpen={showSwap === 'last'} onClose={() => setShowSwap(null)}
        title="Change End (Loughborough)" options={SEGMENT_OPTIONS.lastMile}
        onSelect={(opt) => setJourneyConfig(prev => ({ ...prev, leg3: opt }))}
        currentId={journeyConfig.leg3.id}
      />

    </div>
  );
}
