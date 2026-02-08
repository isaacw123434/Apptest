import { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { MapContainer, TileLayer } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import {
  Train, Car, Bus, Bike, Clock,
  ChevronRight, ChevronLeft,
  X, Zap, ShieldCheck, Leaf, ArrowRight, Footprints
} from 'lucide-react';

// --- DATA CONSTANTS ---

const SEGMENT_OPTIONS = {
  firstMile: [
    {
      id: 'uber',
      label: 'Uber',
      detail: 'St Chads → Leeds Stn',
      time: 14,
      cost: 8.97,
      icon: Car,
      color: 'text-black',
      bgColor: 'bg-zinc-100',
      lineColor: '#000000',
      desc: 'Fastest door-to-door.'
    },
    {
      id: 'bus',
      label: 'Bus (Line 24)',
      detail: '5min walk + 16min bus',
      time: 23,
      cost: 2.00,
      icon: Bus,
      color: 'text-emerald-600',
      bgColor: 'bg-emerald-100',
      lineColor: '#10b981',
      recommended: true,
      desc: 'Best balance.'
    },
    {
      id: 'drive_park',
      label: 'Drive & Park',
      detail: 'Drive to Station',
      time: 15,
      cost: 24.89,
      icon: Car,
      color: 'text-zinc-800',
      bgColor: 'bg-zinc-100',
      lineColor: '#3f3f46',
      desc: 'Flexibility.'
    },
    {
      id: 'train_walk_headingley',
      label: 'Headingley (Walk)',
      detail: '18m Walk + 10m Train',
      time: 28,
      cost: 3.40,
      icon: Footprints,
      color: 'text-slate-600',
      bgColor: 'bg-slate-100',
      lineColor: '#475569',
      desc: 'Walking transfer.'
    },
    {
      id: 'train_uber_headingley',
      label: 'Headingley (Uber)',
      detail: '5m Uber + 10m Train',
      time: 15,
      cost: 9.32,
      icon: Car,
      color: 'text-slate-600',
      bgColor: 'bg-slate-100',
      lineColor: '#475569',
      desc: 'Fast transfer.'
    },
    {
      id: 'cycle',
      label: 'Personal Bike',
      detail: 'Cycle to Station',
      time: 17,
      cost: 0.00,
      icon: Bike,
      color: 'text-blue-600',
      bgColor: 'bg-blue-100',
      lineColor: '#3b82f6',
      desc: 'Zero emissions.'
    }
  ],
  mainLeg: {
    id: 'train_main',
    label: 'CrossCountry',
    detail: 'Leeds → Loughborough',
    time: 102,
    cost: 25.70,
    icon: Train,
    color: 'text-[#713e8d]',
    bgColor: 'bg-indigo-100',
    lineColor: '#713e8d'
  },
  lastMile: [
    {
      id: 'uber',
      label: 'Uber',
      detail: 'Loughborough → East Leake',
      time: 10,
      cost: 14.89,
      icon: Car,
      color: 'text-black',
      bgColor: 'bg-zinc-100',
      lineColor: '#000000',
      desc: 'Reliable final leg.'
    },
    {
      id: 'bus',
      label: 'Bus (Line 1)',
      detail: 'Walk 4min + Bus 10min',
      time: 14,
      cost: 3.00,
      icon: Bus,
      color: 'text-emerald-600',
      bgColor: 'bg-emerald-100',
      lineColor: '#10b981',
      recommended: true,
      desc: 'Short walk required.'
    },
    {
      id: 'cycle',
      label: 'Personal Bike',
      detail: 'Cycle to Dest',
      time: 24,
      cost: 0.00,
      icon: Bike,
      color: 'text-blue-600',
      bgColor: 'bg-blue-100',
      lineColor: '#3b82f6',
      desc: 'Scenic route.'
    }
  ]
};

const DIRECT_DRIVE = {
  time: 110,
  cost: 39.15,
  distance: 87
};

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
                  ? 'border-blue-600 bg-blue-50 ring-1 ring-blue-600'
                  : 'border-slate-100 hover:border-blue-200 hover:bg-slate-50 shadow-sm'
                }`}
            >
              <ModeIcon icon={opt.icon} className={currentId === opt.id ? "bg-blue-200 text-blue-700" : "bg-slate-100 text-slate-600"} />
              <div className="flex-1">
                <div className="flex justify-between items-center mb-1">
                  <span className="font-semibold text-slate-900">{opt.label}</span>
                  <span className="font-bold text-slate-900">£{opt.cost.toFixed(2)}</span>
                </div>
                <div className="flex justify-between text-sm text-slate-500">
                  <span>{opt.time} min</span>
                  {opt.recommended && <span className="text-emerald-600 font-medium text-xs bg-emerald-100 px-2 py-0.5 rounded-full">Best Value</span>}
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

// --- MAP COMPONENTS ---

// 1. SCHEMATIC (For Summary View)
const SchematicMap = ({ leg1, leg3 }) => {
  return (
    <div className="relative h-full w-full bg-slate-50 overflow-hidden">
      <div className="absolute inset-0 opacity-30" style={{backgroundImage: 'radial-gradient(#94a3b8 1px, transparent 1px)', backgroundSize: '16px 16px'}} />
      <svg className="w-full h-full" viewBox="0 0 400 120" preserveAspectRatio="xMidYMid meet">
        {/* Base Track */}
        <line x1="50" y1="60" x2="350" y2="60" className="stroke-slate-200" strokeWidth="4" />

        {/* Active Route Segments */}
        <line x1="50" y1="60" x2="150" y2="60" stroke={leg1.lineColor} strokeWidth="4" strokeLinecap="round" className="transition-colors duration-500" />
        <line x1="150" y1="60" x2="250" y2="60" stroke={SEGMENT_OPTIONS.mainLeg.lineColor} strokeWidth="4" />
        <line x1="250" y1="60" x2="350" y2="60" stroke={leg3.lineColor} strokeWidth="4" strokeLinecap="round" className="transition-colors duration-500" />

        {/* Labels under/above lines */}
        <text x="100" y="75" textAnchor="middle" className="text-[10px] fill-slate-500 font-medium">{leg1.label}</text>
        <text x="200" y="25" textAnchor="middle" className="text-[10px] fill-slate-500 font-medium">{SEGMENT_OPTIONS.mainLeg.label}</text>
        <text x="300" y="75" textAnchor="middle" className="text-[10px] fill-slate-500 font-medium">{leg3.label}</text>

        {/* Nodes */}
        <circle cx="50" cy="60" r="4" className="fill-white stroke-slate-500 stroke-2" />
        <text x="50" y="95" textAnchor="middle" className="text-[10px] fill-slate-500 font-bold uppercase tracking-wider">Start</text>

        <circle cx="150" cy="60" r="6" className="fill-white stroke-2" stroke={SEGMENT_OPTIONS.mainLeg.lineColor} />
        <text x="150" y="45" textAnchor="middle" className="text-[10px] font-bold uppercase tracking-wider" fill={SEGMENT_OPTIONS.mainLeg.lineColor}>Leeds</text>

        <circle cx="250" cy="60" r="6" className="fill-white stroke-2" stroke={SEGMENT_OPTIONS.mainLeg.lineColor} />
        <text x="250" y="45" textAnchor="middle" className="text-[10px] font-bold uppercase tracking-wider" fill={SEGMENT_OPTIONS.mainLeg.lineColor}>Lough</text>

        <circle cx="350" cy="60" r="4" className="fill-slate-800 stroke-white stroke-2" />
        <text x="350" y="95" textAnchor="middle" className="text-[10px] fill-slate-800 font-bold uppercase tracking-wider">End</text>
      </svg>
    </div>
  );
};

SchematicMap.propTypes = {
  leg1: PropTypes.shape({
    id: PropTypes.string.isRequired,
  }).isRequired,
  leg3: PropTypes.shape({
    id: PropTypes.string.isRequired,
  }).isRequired,
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
  const [activeTab, setActiveTab] = useState('smart'); // fastest, cheapest, smart

  // Journey State
  const [journeyConfig, setJourneyConfig] = useState({
    leg1: SEGMENT_OPTIONS.firstMile.find(o => o.id === 'bus'),
    leg3: SEGMENT_OPTIONS.lastMile.find(o => o.id === 'uber')
  });

  const [showSwap, setShowSwap] = useState(null); // 'first' or 'last'
  const [sheetHeight, setSheetHeight] = useState(60);
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
    if (sheetHeight > 75) setSheetHeight(85);
    else if (sheetHeight < 35) setSheetHeight(25);
    else setSheetHeight(60);
  };

  // Update config when Tab changes (only in summary view)
  useEffect(() => {
    if (view === 'summary') {
      if (activeTab === 'fastest') {
        setJourneyConfig({
          leg1: SEGMENT_OPTIONS.firstMile.find(o => o.id === 'uber'),
          leg3: SEGMENT_OPTIONS.lastMile.find(o => o.id === 'uber')
        });
      } else if (activeTab === 'cheapest') {
        setJourneyConfig({
          leg1: SEGMENT_OPTIONS.firstMile.find(o => o.id === 'bus'),
          leg3: SEGMENT_OPTIONS.lastMile.find(o => o.id === 'bus')
        });
      } else {
        setJourneyConfig({
          leg1: SEGMENT_OPTIONS.firstMile.find(o => o.id === 'bus'),
          leg3: SEGMENT_OPTIONS.lastMile.find(o => o.id === 'uber')
        });
      }
    }
  }, [activeTab, view]);

  // Derived Calculations
  const getStationBuffer = (modeId) => {
    if (['uber', 'bus', 'drive_park'].includes(modeId)) return 10;
    return 0;
  };

  const buffer = getStationBuffer(journeyConfig.leg1.id);
  const totalCost = journeyConfig.leg1.cost + SEGMENT_OPTIONS.mainLeg.cost + journeyConfig.leg3.cost;
  const totalTime = journeyConfig.leg1.time + buffer + SEGMENT_OPTIONS.mainLeg.time + journeyConfig.leg3.time;

  const arrivalDate = new Date();
  arrivalDate.setHours(8, 52, 0, 0);
  const destArrivalTime = new Date(arrivalDate.getTime() + (journeyConfig.leg3.time + 5) * 60000);

  const departureDate = new Date();
  departureDate.setHours(7, 10, 0, 0);
  const leaveHomeTime = new Date(departureDate.getTime() - (journeyConfig.leg1.time + buffer) * 60000);

  const formatTime = (date) => date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });


  // --- VIEW 1: SUMMARY PAGE ---
  if (view === 'summary') {
    return (
      <div className="flex flex-col h-screen bg-slate-50 font-sans text-slate-900">

        {/* Header: Schematic Map */}
        <div className="h-48 bg-slate-200 w-full relative">
          <SchematicMap leg1={journeyConfig.leg1} leg3={journeyConfig.leg3} />
          <div className="absolute top-4 left-4 bg-white/90 backdrop-blur px-3 py-1 rounded-full text-xs font-semibold shadow-sm text-slate-600">
             St Chads View → East Leake
          </div>
        </div>

        {/* Tabs */}
        <div className="bg-white flex border-b border-slate-100">
          {[
            { id: 'fastest', label: 'Fastest', icon: Zap },
            { id: 'smart', label: 'Smart Choice', icon: ShieldCheck },
            { id: 'cheapest', label: 'Cheapest', icon: Leaf },
          ].map(tab => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`flex-1 py-4 text-sm font-medium flex flex-col items-center justify-center gap-1 transition-colors border-b-2
                ${activeTab === tab.id
                  ? 'border-blue-600 text-blue-600 bg-blue-50/50'
                  : 'border-transparent text-slate-400 hover:text-slate-600'}`}
            >
              <tab.icon size={18} />
              {tab.label}
            </button>
          ))}
        </div>

        {/* Main Content: Basic Summary Card */}
        <div className="p-6">
          <div
            onClick={() => setView('detail')}
            className="bg-white rounded-2xl shadow-lg border border-slate-200 overflow-hidden cursor-pointer hover:shadow-xl hover:scale-[1.02] transition-all duration-300"
          >
            <div className={`h-2 w-full ${activeTab === 'smart' ? 'bg-emerald-500' : activeTab === 'fastest' ? 'bg-indigo-600' : 'bg-blue-500'}`}></div>

            <div className="p-6">
              <div className="flex justify-between items-start mb-6">
                 <div>
                   <h2 className="text-4xl font-bold text-slate-900">£{totalCost.toFixed(2)}</h2>
                   <div className="flex items-center gap-2 text-slate-500 text-sm mt-2 font-medium">
                     <Clock size={16} /> {Math.floor(totalTime/60)}h {totalTime%60}m Total
                   </div>
                 </div>
                 <div className="bg-slate-100 p-2 rounded-full text-slate-400">
                   <ChevronRight size={24} />
                 </div>
              </div>

              {/* Simple Route Chain Display */}
              <div className="flex items-center justify-between gap-2 mb-2">
                 {/* Leg 1 */}
                 <div className="flex items-center gap-2 bg-slate-50 px-3 py-2 rounded-lg border border-slate-100 flex-1">
                    <journeyConfig.leg1.icon size={20} className="text-slate-700" />
                    <div className="flex flex-col">
                       <span className="text-sm font-semibold text-slate-900 leading-tight">{journeyConfig.leg1.label}</span>
                       <span className="text-[10px] text-slate-500 font-medium">{journeyConfig.leg1.time} min • £{journeyConfig.leg1.cost.toFixed(2)}</span>
                    </div>
                 </div>
                 <ArrowRight size={16} className="text-slate-300 flex-shrink-0" />

                 {/* Leg 2 */}
                 <div className="flex items-center gap-2 bg-indigo-50 px-3 py-2 rounded-lg border border-indigo-100 flex-1">
                    <Train size={20} className="text-[#713e8d]" />
                    <div className="flex flex-col">
                       <span className="text-sm font-bold text-[#713e8d] leading-tight">{SEGMENT_OPTIONS.mainLeg.label}</span>
                       <span className="text-[10px] text-slate-500 font-medium">{SEGMENT_OPTIONS.mainLeg.time} min • £{SEGMENT_OPTIONS.mainLeg.cost.toFixed(2)}</span>
                    </div>
                 </div>
                 <ArrowRight size={16} className="text-slate-300 flex-shrink-0" />

                 {/* Leg 3 */}
                 <div className="flex items-center gap-2 bg-slate-50 px-3 py-2 rounded-lg border border-slate-100 flex-1">
                    <journeyConfig.leg3.icon size={20} className="text-slate-700" />
                    <div className="flex flex-col">
                       <span className="text-sm font-semibold text-slate-900 leading-tight">{journeyConfig.leg3.label}</span>
                       <span className="text-[10px] text-slate-500 font-medium">{journeyConfig.leg3.time} min • £{journeyConfig.leg3.cost.toFixed(2)}</span>
                    </div>
                 </div>
              </div>
              <p className="text-center text-xs text-slate-400 mt-4">Tap card to customize first/last mile</p>
            </div>
          </div>

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
      <div className="absolute top-0 left-0 right-0 bottom-0 z-0 h-[60%]">
        <MapContainer
          center={[52.8, -1.3]}
          zoom={9}
          style={{ width: "100%", height: "100%" }}
          zoomControl={false}
        >
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />
        </MapContainer>

        {/* Navigation Control */}
        <div className="absolute top-6 left-6 z-20">
          <button
            onClick={() => setView('summary')}
            className="bg-white/90 backdrop-blur px-4 py-2 rounded-full shadow-lg hover:bg-white transition-colors flex items-center gap-2 text-sm font-bold text-slate-700"
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
        <div className="px-6 py-4 border-b border-slate-50 shrink-0 flex justify-between items-end">
           <div>
             <h2 className="text-2xl font-bold text-slate-900">£{totalCost.toFixed(2)}</h2>
             <div className="flex items-center gap-2 text-sm text-slate-500">
               <Clock size={14} /> {Math.floor(totalTime / 60)}h {totalTime % 60}m
             </div>
           </div>
           <div className="text-right">
              <span className="text-xs font-semibold text-emerald-600 bg-emerald-50 px-2 py-1 rounded-md">
                Interactive Route
              </span>
           </div>
        </div>

        {/* DETAILED TIMELINE (Copied from previous "First Page" logic) */}
        <div className="flex-1 overflow-y-auto px-6 py-6 custom-scrollbar pb-24">
          <div className="relative pl-4 space-y-0">
            {/* Timeline Vertical Bar */}
            <div className="absolute left-[27px] top-4 bottom-4 w-1 bg-slate-100 rounded-full"></div>

            {/* 1. START TIME */}
            <div className="flex gap-4 min-h-[40px]">
              <div className="w-16 text-right text-xs text-slate-500 font-mono py-1">{formatTime(leaveHomeTime)}</div>
              <div className="flex flex-col items-center z-10">
                <div className="w-3 h-3 rounded-full bg-slate-400"></div>
              </div>
              <div className="pb-6"><div className="text-sm font-semibold text-slate-700">Start Journey</div></div>
            </div>

            {/* 2. LEG 1 (SWAPPABLE) */}
            <div className="flex gap-4 group">
              <div className="w-16 text-right text-xs text-slate-400 font-mono pt-4">{journeyConfig.leg1.time} min</div>
              <div className="flex flex-col items-center z-10">
                <div className={`w-3 h-3 rounded-full border-2 bg-white ${journeyConfig.leg1.id === 'uber' ? 'border-zinc-500' : 'border-emerald-500'}`}></div>
              </div>
              <div className="pb-8 flex-1">
                <button
                  onClick={() => setShowSwap('first')}
                  className={`w-full text-left relative p-3 rounded-2xl border transition-all duration-300 shadow-sm
                    ${journeyConfig.leg1.bgColor} border-transparent hover:border-blue-300 hover:shadow-md active:scale-95`}
                >
                  <div className="flex justify-between items-center mb-1">
                     <div className="flex items-center gap-2">
                       <journeyConfig.leg1.icon size={18} className={journeyConfig.leg1.color} />
                       <span className="font-bold text-slate-800">{journeyConfig.leg1.label}</span>
                     </div>
                     <span className="font-bold text-slate-900">£{journeyConfig.leg1.cost.toFixed(2)}</span>
                  </div>
                  <div className="flex justify-between items-center mt-2">
                    <span className="text-xs text-slate-500">{journeyConfig.leg1.detail}</span>
                    <span className="text-[10px] font-bold text-blue-600 bg-white/60 px-2 py-0.5 rounded backdrop-blur-sm">CHANGE</span>
                  </div>
                </button>
              </div>
            </div>

            {/* 3. TRANSFER */}
            <div className="flex gap-4 min-h-[30px]">
              <div className="w-16 text-right text-xs text-slate-500 font-mono">07:05</div>
              <div className="flex flex-col items-center z-10">
                <div className="w-2 h-2 rounded-full border-2 border-slate-300 bg-white"></div>
              </div>
              <div className="pb-4 pt-0"><div className="text-xs font-medium text-slate-400 uppercase">Transfer @ Leeds</div></div>
            </div>

            {/* 4. MAIN LEG (FIXED) */}
            <div className="flex gap-4">
              <div className="w-16 text-right text-xs text-slate-400 font-mono pt-4">1h 42m</div>
              <div className="flex flex-col items-center z-10">
                 <div className="w-4 h-4 rounded-full border-4 border-indigo-600 bg-white"></div>
              </div>
              <div className="pb-8 flex-1">
                <div className="w-full bg-slate-50 border border-slate-100 rounded-xl p-3 flex items-center gap-3 opacity-80">
                  <Train size={18} className="text-indigo-600" />
                  <div className="flex-1">
                    <div className="flex justify-between">
                      <span className="font-semibold text-slate-800">Train (CrossCountry)</span>
                      <span className="font-bold text-slate-900">£25.70</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* 5. LEG 3 (SWAPPABLE) */}
            <div className="flex gap-4 group">
              <div className="w-16 text-right text-xs text-slate-400 font-mono pt-4">{journeyConfig.leg3.time} min</div>
              <div className="flex flex-col items-center z-10">
                <div className={`w-3 h-3 rounded-full border-2 bg-white ${journeyConfig.leg3.id === 'uber' ? 'border-zinc-500' : 'border-blue-500'}`}></div>
              </div>
              <div className="pb-8 flex-1">
                <button
                  onClick={() => setShowSwap('last')}
                  className={`w-full text-left relative p-3 rounded-2xl border transition-all duration-300 shadow-sm
                    ${journeyConfig.leg3.bgColor} border-transparent hover:border-blue-300 hover:shadow-md active:scale-95`}
                >
                  <div className="flex justify-between items-center mb-1">
                     <div className="flex items-center gap-2">
                       <journeyConfig.leg3.icon size={18} className={journeyConfig.leg3.color} />
                       <span className="font-bold text-slate-800">{journeyConfig.leg3.label}</span>
                     </div>
                     <span className="font-bold text-slate-900">£{journeyConfig.leg3.cost.toFixed(2)}</span>
                  </div>
                  <div className="flex justify-between items-center mt-2">
                    <span className="text-xs text-slate-500">{journeyConfig.leg3.detail}</span>
                    <span className="text-[10px] font-bold text-blue-600 bg-white/60 px-2 py-0.5 rounded backdrop-blur-sm">CHANGE</span>
                  </div>
                </button>
              </div>
            </div>

            {/* 6. ARRIVAL */}
            <div className="flex gap-4 min-h-[40px]">
              <div className="w-16 text-right text-xs text-slate-500 font-mono py-1">{formatTime(destArrivalTime)}</div>
              <div className="flex flex-col items-center z-10">
                <div className="w-3 h-3 rounded-full bg-slate-800"></div>
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