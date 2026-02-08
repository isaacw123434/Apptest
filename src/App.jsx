import { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import {
  Train, Car, Bus, Bike, Clock,
  ChevronRight, ChevronLeft,
  X, Zap, ShieldCheck, Leaf, ArrowRight, Footprints,
  Navigation
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
      co2: 'High',
      desc: 'Fastest door-to-door.'
    },
    {
      id: 'bus',
      label: 'Bus (Line 24)',
      detail: '5min walk + 16min bus',
      time: 23,
      cost: 2.00,
      icon: Bus,
      co2: 'Low',
      recommended: true,
      desc: 'Best balance of cost/time.'
    },
    {
      id: 'cycle',
      label: 'Personal Bike',
      detail: 'Cycle to Station Storage',
      time: 17,
      cost: 0.00,
      icon: Bike,
      co2: 'Zero',
      desc: 'Free, requires shower at office?'
    },
    {
      id: 'drive_park',
      label: 'Drive & Park',
      detail: 'Station Parking (24h)',
      time: 15,
      cost: 24.89, // 1.89 fuel + 23 parking
      icon: Car,
      co2: 'High',
      desc: 'Expensive parking fees.'
    },
    {
      id: 'walk_train',
      label: 'Walk + Local Train',
      detail: 'Walk to Headingley',
      time: 28,
      cost: 3.40,
      icon: Footprints,
      co2: 'Low',
      desc: 'Healthy, but risk of rain.'
    }
  ],
  mainLeg: {
    id: 'train_main',
    label: 'CrossCountry / EMR',
    detail: 'Leeds → Loughborough',
    time: 102, // 1h 42m
    cost: 25.70,
    icon: Train,
    co2: 'Med'
  },
  lastMile: [
    {
      id: 'uber',
      label: 'Uber',
      detail: 'Loughborough → East Leake',
      time: 10,
      cost: 14.89,
      icon: Car,
      co2: 'High',
      desc: 'Reliable for final leg.'
    },
    {
      id: 'bus',
      label: 'Bus (Line 1)',
      detail: 'Walk 4min + Bus 10min',
      time: 14,
      cost: 3.00,
      icon: Bus,
      co2: 'Low',
      recommended: true,
      desc: 'Short walk required.'
    },
    {
      id: 'cycle',
      label: 'Personal Bike',
      detail: 'Folding bike / Hire',
      time: 24,
      cost: 0.00,
      icon: Bike,
      co2: 'Zero',
      desc: 'Good exercise.'
    }
  ]
};

const DIRECT_DRIVE = {
  time: 110, // 1h 50m
  cost: 62.15, // 87mi * 0.45 + parking estimate
  distance: 87
};

// --- SUB-COMPONENTS ---

const ModeIcon = ({ icon: Icon, className = "" }) => (
  <div className={`p-2 rounded-full bg-slate-100 ${className}`}>
    <Icon size={20} className="text-slate-700" />
  </div>
);

ModeIcon.propTypes = {
  icon: PropTypes.elementType.isRequired,
  className: PropTypes.string,
};

const SwapModal = ({ isOpen, onClose, title, options, onSelect, currentId }) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/50 backdrop-blur-sm p-4 animate-in fade-in">
      <div className="bg-white w-full max-w-md rounded-2xl shadow-2xl overflow-hidden animate-in slide-in-from-bottom-10">
        <div className="p-4 border-b flex justify-between items-center bg-slate-50">
          <h3 className="font-semibold text-lg text-slate-800">{title}</h3>
          <button onClick={onClose} className="p-1 hover:bg-slate-200 rounded-full">
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
                  : 'border-slate-200 hover:border-blue-300 hover:bg-slate-50'
                }`}
            >
              <ModeIcon icon={opt.icon} className={currentId === opt.id ? "bg-blue-200" : "bg-slate-100"} />
              <div className="flex-1">
                <div className="flex justify-between items-center mb-1">
                  <span className="font-semibold text-slate-900">{opt.label}</span>
                  <span className="font-bold text-slate-900">£{opt.cost.toFixed(2)}</span>
                </div>
                <div className="flex justify-between text-sm text-slate-500">
                  <span>{opt.time} min • {opt.co2} CO₂</span>
                  {opt.recommended && <span className="text-emerald-600 font-medium text-xs bg-emerald-100 px-2 py-0.5 rounded-full">Smart Choice</span>}
                </div>
                <div className="text-xs text-slate-400 mt-1">{opt.desc}</div>
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
    desc: PropTypes.string,
    recommended: PropTypes.bool,
    co2: PropTypes.string,
  })).isRequired,
  onSelect: PropTypes.func.isRequired,
  currentId: PropTypes.string.isRequired,
};

// --- MAP COMPONENTS ---

// 1. SCHEMATIC (For Summary View and Detail View)
const SchematicMap = ({ leg1, leg3 }) => {
  const getMapColor = (modeId) => {
    if (modeId === 'uber' || modeId === 'drive_park') return 'stroke-orange-500';
    if (modeId === 'bus' || modeId === 'walk_train') return 'stroke-emerald-500';
    if (modeId === 'cycle') return 'stroke-blue-500';
    return 'stroke-slate-300';
  };

  return (
    <div className="relative h-full w-full bg-slate-50 overflow-hidden">
      <div className="absolute inset-0 opacity-30" style={{backgroundImage: 'radial-gradient(#94a3b8 1px, transparent 1px)', backgroundSize: '16px 16px'}} />
      <svg className="w-full h-full" viewBox="0 0 400 120" preserveAspectRatio="xMidYMid meet">
        {/* Base Track */}
        <line x1="50" y1="60" x2="350" y2="60" className="stroke-slate-300" strokeWidth="4" strokeDasharray="4 4" />

        {/* Active Route Segments */}
        <line x1="50" y1="60" x2="150" y2="60" className={`${getMapColor(leg1.id)} transition-colors duration-500`} strokeWidth="4" />
        <line x1="150" y1="60" x2="250" y2="60" className="stroke-indigo-600" strokeWidth="6" />
        <line x1="250" y1="60" x2="350" y2="60" className={`${getMapColor(leg3.id)} transition-colors duration-500`} strokeWidth="4" />

        {/* Nodes */}
        <circle cx="50" cy="60" r="6" className="fill-white stroke-slate-500 stroke-2" />
        <text x="50" y="85" textAnchor="middle" className="text-[10px] fill-slate-500 font-bold uppercase">St Chads</text>

        <circle cx="150" cy="60" r="8" className="fill-white stroke-indigo-600 stroke-2" />
        <text x="150" y="40" textAnchor="middle" className="text-[10px] fill-indigo-600 font-bold uppercase">Leeds Stn</text>

        <circle cx="250" cy="60" r="8" className="fill-white stroke-indigo-600 stroke-2" />
        <text x="250" y="40" textAnchor="middle" className="text-[10px] fill-indigo-600 font-bold uppercase">Loughboro</text>

        <circle cx="350" cy="60" r="6" className="fill-slate-800 stroke-white stroke-2" />
        <text x="350" y="85" textAnchor="middle" className="text-[10px] fill-slate-800 font-bold uppercase">East Leake</text>
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

// --- MAIN APP ---

export default function JourneyPlanner() {
  const [view, setView] = useState('summary'); // 'summary' or 'detail'
  const [activeTab, setActiveTab] = useState('smart'); // fastest, cheapest, smart

  // Journey State
  const [journeyConfig, setJourneyConfig] = useState({
    leg1: SEGMENT_OPTIONS.firstMile.find(o => o.id === 'bus'),
    leg3: SEGMENT_OPTIONS.lastMile.find(o => o.id === 'bus')
  });

  const [showSwap, setShowSwap] = useState(null); // 'first' or 'last'

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
          leg1: SEGMENT_OPTIONS.firstMile.find(o => o.id === 'cycle'),
          leg3: SEGMENT_OPTIONS.lastMile.find(o => o.id === 'cycle')
        });
      } else {
        // smart
        setJourneyConfig({
          leg1: SEGMENT_OPTIONS.firstMile.find(o => o.id === 'bus'),
          leg3: SEGMENT_OPTIONS.lastMile.find(o => o.id === 'bus')
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
                 <div className="flex items-center gap-2 bg-slate-50 px-3 py-2 rounded-lg border border-slate-100">
                    <journeyConfig.leg1.icon size={18} className="text-slate-700" />
                    <span className="text-sm font-semibold text-slate-700">{journeyConfig.leg1.label.split(' ')[0]}</span>
                 </div>
                 <ArrowRight size={16} className="text-slate-300" />

                 {/* Leg 2 */}
                 <div className="flex items-center gap-2 bg-indigo-50 px-3 py-2 rounded-lg border border-indigo-100">
                    <Train size={18} className="text-indigo-600" />
                    <span className="text-sm font-semibold text-indigo-700">Train</span>
                 </div>
                 <ArrowRight size={16} className="text-slate-300" />

                 {/* Leg 3 */}
                 <div className="flex items-center gap-2 bg-slate-50 px-3 py-2 rounded-lg border border-slate-100">
                    <journeyConfig.leg3.icon size={18} className="text-slate-700" />
                    <span className="text-sm font-semibold text-slate-700">{journeyConfig.leg3.label.split(' ')[0]}</span>
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
    <div className="flex flex-col h-screen bg-slate-50 font-sans text-slate-900">

      {/* --- TOP: MAP & CONTEXT --- */}
      <div className="h-1/3 bg-slate-200 relative overflow-hidden flex items-center justify-center">
        <SchematicMap leg1={journeyConfig.leg1} leg3={journeyConfig.leg3} />

        {/* Back Button */}
        <div className="absolute top-6 left-6 z-20">
          <button
            onClick={() => setView('summary')}
            className="bg-white/90 backdrop-blur px-4 py-2 rounded-full shadow-lg hover:bg-white transition-colors flex items-center gap-2 text-sm font-bold text-slate-700"
          >
            <ChevronLeft size={16} /> Back
          </button>
        </div>

        <div className="absolute top-4 right-4 bg-white/90 backdrop-blur px-3 py-1 rounded-full text-xs font-semibold shadow-sm text-slate-600 border border-slate-200">
           St Chads View → East Leake
        </div>
      </div>

      {/* --- BOTTOM: CONTROLS & TIMELINE --- */}
      <div className="flex-1 flex flex-col bg-white rounded-t-3xl shadow-[0_-4px_20px_rgba(0,0,0,0.1)] -mt-6 z-20 overflow-hidden">

        {/* TABS */}
        <div className="flex border-b border-slate-100">
          {[
            { id: 'fastest', label: 'Fastest', icon: Zap },
            { id: 'smart', label: 'Smart Choice', icon: ShieldCheck },
            { id: 'cheapest', label: 'Cheapest', icon: Leaf },
          ].map(tab => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`flex-1 py-4 text-sm font-medium flex items-center justify-center gap-2 transition-colors
                ${activeTab === tab.id
                  ? 'text-blue-600 border-b-2 border-blue-600 bg-blue-50/50'
                  : 'text-slate-500 hover:bg-slate-50'}`}
            >
              <tab.icon size={18} /> {tab.label}
            </button>
          ))}
        </div>

        {/* SUMMARY HEADER */}
        <div className="px-6 py-4 bg-white border-b border-slate-100 flex justify-between items-center">
          <div>
            <div className="text-3xl font-bold text-slate-900 flex items-center gap-2">
              £{totalCost.toFixed(2)}
              {totalCost > 40 && <span className="text-xs bg-amber-100 text-amber-700 px-2 py-1 rounded-full font-medium">Review Policy</span>}
              {totalCost < 35 && <span className="text-xs bg-emerald-100 text-emerald-700 px-2 py-1 rounded-full font-medium">In Policy</span>}
            </div>
            <div className="text-sm text-slate-500 mt-1 flex items-center gap-2">
              <Clock size={14} />
              {Math.floor(totalTime / 60)}h {totalTime % 60}m Total
              <span className="text-slate-300">|</span>
              <span className="text-slate-700">Arrive {formatTime(destArrivalTime)}</span>
            </div>
          </div>

          {/* Comparison vs Drive */}
          <div className="text-right hidden sm:block">
            <div className="text-xs text-slate-400">vs Direct Drive</div>
            <div className="text-xs font-semibold text-slate-600 line-through decoration-red-500">
              £{DIRECT_DRIVE.cost.toFixed(2)} • 1h 50m
            </div>
          </div>
        </div>

        {/* TIMELINE SCROLL AREA */}
        <div className="flex-1 overflow-y-auto p-4 space-y-0">

          {/* 1. START NODE */}
          <div className="flex gap-4 min-h-[40px]">
            <div className="w-16 text-right text-xs text-slate-500 font-mono py-1">{formatTime(leaveHomeTime)}</div>
            <div className="flex flex-col items-center">
              <div className="w-3 h-3 rounded-full bg-slate-400"></div>
              <div className="w-0.5 flex-1 bg-slate-200"></div>
            </div>
            <div className="pb-6">
              <div className="text-sm font-semibold text-slate-700">Start from St Chads View</div>
            </div>
          </div>

          {/* 2. LEG 1 (INTERACTIVE) */}
          <div className="flex gap-4 group">
            <div className="w-16 text-right text-xs text-slate-400 font-mono pt-4">{journeyConfig.leg1.time} min</div>
            <div className="flex flex-col items-center">
              <div className="w-0.5 h-full bg-slate-200"></div>
            </div>
            <div className="pb-8 flex-1">
              <button
                onClick={() => setShowSwap('first')}
                className="w-full bg-white border border-slate-200 rounded-xl p-3 shadow-sm hover:shadow-md hover:border-blue-300 transition-all text-left flex items-center gap-3 relative overflow-hidden group-hover:ring-1 group-hover:ring-slate-300"
              >
                {/* Visual Cue that this is swappable */}
                <div className="absolute right-0 top-0 bottom-0 w-1 bg-blue-500 opacity-0 group-hover:opacity-100 transition-opacity"></div>

                <ModeIcon icon={journeyConfig.leg1.icon} className="bg-blue-50 text-blue-600" />
                <div className="flex-1">
                  <div className="flex justify-between">
                    <span className="font-semibold text-slate-800">{journeyConfig.leg1.label}</span>
                    <span className="font-bold text-slate-900">£{journeyConfig.leg1.cost.toFixed(2)}</span>
                  </div>
                  <div className="text-xs text-slate-500 truncate">{journeyConfig.leg1.detail}</div>
                </div>
                <div className="bg-slate-100 rounded-full p-1 text-slate-400 group-hover:text-blue-600 group-hover:bg-blue-50 transition-colors">
                  <ChevronRight size={16} />
                </div>
              </button>
            </div>
          </div>

          {/* 3. TRANSFER NODE */}
          <div className="flex gap-4 min-h-[30px]">
            <div className="w-16 text-right text-xs text-slate-500 font-mono">07:05</div>
            <div className="flex flex-col items-center">
              <div className="w-2 h-2 rounded-full border-2 border-slate-300 bg-white"></div>
              <div className="w-0.5 flex-1 border-l-2 border-dotted border-slate-300 mx-auto"></div>
            </div>
            <div className="pb-4 pt-0">
              <div className="text-xs font-medium text-slate-500 uppercase tracking-wide">Transfer @ Leeds Stn</div>
            </div>
          </div>

          {/* 4. MAIN LEG (FIXED) */}
          <div className="flex gap-4">
            <div className="w-16 text-right text-xs text-slate-400 font-mono pt-4">1h 42m</div>
            <div className="flex flex-col items-center">
              <div className="w-1 h-full bg-indigo-500"></div>
            </div>
            <div className="pb-8 flex-1">
              <div className="w-full bg-slate-50 border border-slate-100 rounded-xl p-3 flex items-center gap-3 opacity-90">
                <ModeIcon icon={Train} className="bg-indigo-100 text-indigo-700" />
                <div className="flex-1">
                  <div className="flex justify-between">
                    <span className="font-semibold text-slate-800">CrossCountry / EMR</span>
                    <span className="font-bold text-slate-900">£25.70</span>
                  </div>
                  <div className="text-xs text-slate-500">07:10 — 08:52 • On Time</div>
                </div>
              </div>
            </div>
          </div>

          {/* 5. TRANSFER NODE */}
          <div className="flex gap-4 min-h-[30px]">
            <div className="w-16 text-right text-xs text-slate-500 font-mono">08:52</div>
            <div className="flex flex-col items-center">
              <div className="w-2 h-2 rounded-full border-2 border-slate-300 bg-white"></div>
              <div className="w-0.5 flex-1 border-l-2 border-dotted border-slate-300 mx-auto"></div>
            </div>
            <div className="pb-4 pt-0">
              <div className="text-xs font-medium text-slate-500 uppercase tracking-wide">Transfer @ Loughborough</div>
            </div>
          </div>

           {/* 6. LEG 3 (INTERACTIVE) */}
           <div className="flex gap-4 group">
            <div className="w-16 text-right text-xs text-slate-400 font-mono pt-4">{journeyConfig.leg3.time} min</div>
            <div className="flex flex-col items-center">
              <div className="w-0.5 h-full bg-slate-200"></div>
            </div>
            <div className="pb-8 flex-1">
              <button
                onClick={() => setShowSwap('last')}
                className="w-full bg-white border border-slate-200 rounded-xl p-3 shadow-sm hover:shadow-md hover:border-blue-300 transition-all text-left flex items-center gap-3 group-hover:ring-1 group-hover:ring-slate-300"
              >
                <ModeIcon icon={journeyConfig.leg3.icon} className="bg-blue-50 text-blue-600" />
                <div className="flex-1">
                  <div className="flex justify-between">
                    <span className="font-semibold text-slate-800">{journeyConfig.leg3.label}</span>
                    <span className="font-bold text-slate-900">£{journeyConfig.leg3.cost.toFixed(2)}</span>
                  </div>
                  <div className="text-xs text-slate-500 truncate">{journeyConfig.leg3.detail}</div>
                </div>
                 <div className="bg-slate-100 rounded-full p-1 text-slate-400 group-hover:text-blue-600 group-hover:bg-blue-50 transition-colors">
                  <ChevronRight size={16} />
                </div>
              </button>
            </div>
          </div>

          {/* 7. END NODE */}
          <div className="flex gap-4 min-h-[40px]">
            <div className="w-16 text-right text-xs text-slate-500 font-mono py-1">{formatTime(destArrivalTime)}</div>
            <div className="flex flex-col items-center">
              <div className="w-3 h-3 rounded-full bg-slate-800"></div>
            </div>
            <div>
              <div className="text-sm font-semibold text-slate-700">Arrive East Leake</div>
            </div>
          </div>

        </div>

        {/* BOTTOM ACTION */}
        <div className="p-4 bg-white border-t border-slate-100 pb-8 sm:pb-4">
          <button className="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-3 px-4 rounded-xl shadow-lg shadow-indigo-200 transition-all transform active:scale-95 flex items-center justify-center gap-2">
            Book Journey <Navigation size={18} />
          </button>
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