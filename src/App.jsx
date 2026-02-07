import React, { useState, useEffect } from 'react';
import { 
  Train, Car, Bus, Bike, MapPin, Clock, 
  ChevronRight, ChevronLeft, Navigation, 
  X, Circle, Disc, ArrowRight, Leaf, Map as MapIcon,
  ShieldCheck, Zap
} from 'lucide-react';

// --- DATA MOCK ---

const SEGMENT_OPTIONS = {
  firstMile: [
    { 
      id: 'uber', 
      label: 'Uber', 
      detail: 'St Chads → Leeds Stn', 
      time: 14, 
      cost: 8.97, 
      icon: Car, 
      color: 'text-zinc-800',
      bgColor: 'bg-zinc-100',
      lineColor: '#3f3f46', 
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
      desc: 'Best balance of cost/time.'
    },
    { 
      id: 'cycle', 
      label: 'Personal Bike', 
      detail: 'Cycle to Station Storage', 
      time: 17, 
      cost: 0.00, 
      icon: Bike, 
      color: 'text-blue-600',
      bgColor: 'bg-blue-100',
      lineColor: '#3b82f6', 
      desc: 'Free, requires shower at office?'
    },
    { 
      id: 'drive_park', 
      label: 'Drive & Park', 
      detail: 'Station Parking (24h)', 
      time: 15, 
      cost: 24.89, 
      icon: Car, 
      color: 'text-zinc-800',
      bgColor: 'bg-zinc-100',
      lineColor: '#3f3f46',
      desc: 'Expensive parking fees.'
    }
  ],
  mainLeg: {
    id: 'train_main',
    label: 'CrossCountry / EMR',
    detail: 'Leeds → Loughborough',
    time: 102, // 1h 42m
    cost: 25.70,
    icon: Train,
    color: 'text-indigo-600',
    bgColor: 'bg-indigo-100',
    lineColor: '#4f46e5'
  },
  lastMile: [
    { 
      id: 'uber', 
      label: 'Uber', 
      detail: 'Loughborough → East Leake', 
      time: 10, 
      cost: 14.89, 
      icon: Car, 
      color: 'text-zinc-800',
      bgColor: 'bg-zinc-100',
      lineColor: '#3f3f46',
      desc: 'Reliable for final leg.'
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
      label: 'Hire Bike', 
      detail: 'Station Dock', 
      time: 24, 
      cost: 3.50, 
      icon: Bike, 
      color: 'text-blue-600',
      bgColor: 'bg-blue-100',
      lineColor: '#3b82f6',
      desc: 'Good exercise.'
    }
  ]
};

const DIRECT_DRIVE = {
  time: 110, 
  cost: 62.15, 
  distance: 87
};

// --- COMPONENTS ---

const ModeIcon = ({ icon: Icon, className = "" }) => (
  <div className={`p-2 rounded-full ${className}`}>
    <Icon size={20} />
  </div>
);

const SwapModal = ({ isOpen, onClose, title, options, onSelect, currentId }) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[60] flex items-end sm:items-center justify-center bg-black/50 backdrop-blur-sm p-4 animate-in fade-in">
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
              <ModeIcon icon={opt.icon} className={currentId === opt.id ? "bg-blue-200 text-blue-700" : "bg-slate-100 text-slate-600"} />
              <div className="flex-1">
                <div className="flex justify-between items-center mb-1">
                  <span className="font-semibold text-slate-900">{opt.label}</span>
                  <span className="font-bold text-slate-900">£{opt.cost.toFixed(2)}</span>
                </div>
                <div className="flex justify-between text-sm text-slate-500">
                  <span>{opt.time} min</span>
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

// --- REALISTIC MAP ENGINE (For Detail View) ---

const RealisticMap = ({ leg1, leg3, focusedSegment }) => {
  const getViewBox = () => {
    if (focusedSegment === 'first') return "20 120 160 80"; // Zoom Leeds
    if (focusedSegment === 'last') return "220 20 160 80"; // Zoom Loughborough
    return "0 0 400 220"; // Full View
  };

  return (
    <div className="relative w-full h-full bg-[#e5e7eb] overflow-hidden transition-transform duration-700 ease-in-out">
      <svg 
        className="w-full h-full transition-all duration-700 ease-in-out" 
        viewBox={getViewBox()} 
        preserveAspectRatio="xMidYMid slice"
      >
        {/* Background Land */}
        <rect width="400" height="220" fill="#f3f4f6" />

        {/* River / Water Bodies */}
        <path d="M-10,180 Q100,160 150,130 T410,140" fill="none" stroke="#bfdbfe" strokeWidth="15" />
        <path d="M120,230 Q140,180 130,140" fill="none" stroke="#bfdbfe" strokeWidth="8" />

        {/* Parks / Greenery */}
        <path d="M40,140 L80,140 L90,170 L30,180 Z" fill="#dcfce7" />
        <path d="M280,40 L350,30 L360,70 L300,80 Z" fill="#dcfce7" />
        
        {/* Major Roads (White Lines) */}
        <g stroke="white" strokeWidth="4" fill="none">
          <path d="M0,200 L400,100" />
          <path d="M50,0 L100,220" />
          <path d="M200,0 L250,220" />
          <path d="M300,0 L350,220" />
        </g>
        
        {/* City Blocks (Simulated) */}
        <g fill="#e5e7eb">
           <rect x="50" y="130" width="20" height="20" />
           <rect x="130" y="90" width="40" height="40" /> {/* Leeds Center */}
           <rect x="330" y="40" width="40" height="40" /> {/* Loughborough Center */}
        </g>

        {/* --- ROUTES --- */}
        {/* Leg 1: St Chads -> Leeds */}
        <path 
          d="M50,160 Q80,160 140,110" 
          fill="none" 
          stroke={leg1.lineColor} 
          strokeWidth="4" 
          strokeLinecap="round"
          strokeDasharray={leg1.id === 'bus' ? '0' : leg1.id === 'walk' ? '3 3' : '0'}
          className="drop-shadow-md"
        />

        {/* Leg 2: Train (Leeds -> Loughborough) */}
        <path 
          d="M140,110 Q240,110 340,60" 
          fill="none" 
          stroke="#4f46e5" 
          strokeWidth="4" 
          strokeDasharray="6 4"
          className="opacity-60"
        />

        {/* Leg 3: Loughborough -> East Leake */}
        <path 
          d="M340,60 Q360,60 380,30" 
          fill="none" 
          stroke={leg3.lineColor} 
          strokeWidth="4" 
          strokeLinecap="round"
          className="drop-shadow-md"
        />

        {/* --- MARKERS --- */}
        <circle cx="50" cy="160" r="3" fill="white" stroke="#64748b" strokeWidth="2" />
        <circle cx="140" cy="110" r="4" fill="white" stroke="#4f46e5" strokeWidth="2" />
        <circle cx="340" cy="60" r="4" fill="white" stroke="#4f46e5" strokeWidth="2" />
        <circle cx="380" cy="30" r="3" fill="#1e293b" stroke="white" strokeWidth="1" />
      </svg>
      
      {focusedSegment && (
        <div className="absolute top-4 left-4 bg-white/90 backdrop-blur px-3 py-1.5 rounded-lg shadow-sm border border-slate-200 text-xs font-bold text-slate-700 animate-in fade-in">
          {focusedSegment === 'first' ? 'Zoom: Leeds Area' : 'Zoom: Loughborough Area'}
        </div>
      )}
    </div>
  );
};

// --- MAIN APP ---

export default function JourneyPlanner() {
  const [view, setView] = useState('summary'); // 'summary' or 'map'
  const [activeTab, setActiveTab] = useState('smart'); // fastest, cheapest, smart
  
  const [leg1, setLeg1] = useState(SEGMENT_OPTIONS.firstMile[1]); // Default Bus
  const [leg3, setLeg3] = useState(SEGMENT_OPTIONS.lastMile[1]); // Default Bus
  const [showSwap, setShowSwap] = useState(null);

  // Auto-select modes based on tabs
  useEffect(() => {
    if (activeTab === 'fastest') {
      setLeg1(SEGMENT_OPTIONS.firstMile.find(o => o.id === 'uber'));
      setLeg3(SEGMENT_OPTIONS.lastMile.find(o => o.id === 'uber'));
    } else if (activeTab === 'cheapest') {
      setLeg1(SEGMENT_OPTIONS.firstMile.find(o => o.id === 'cycle'));
      setLeg3(SEGMENT_OPTIONS.lastMile.find(o => o.id === 'cycle'));
    } else if (activeTab === 'smart') {
      setLeg1(SEGMENT_OPTIONS.firstMile.find(o => o.id === 'bus'));
      setLeg3(SEGMENT_OPTIONS.lastMile.find(o => o.id === 'bus'));
    }
  }, [activeTab]);

  // Calculations
  const totalCost = leg1.cost + SEGMENT_OPTIONS.mainLeg.cost + leg3.cost;
  const totalTime = leg1.time + SEGMENT_OPTIONS.mainLeg.time + leg3.time;
  
  const arrivalDate = new Date();
  arrivalDate.setHours(8, 52, 0, 0);
  const destArrivalTime = new Date(arrivalDate.getTime() + (leg3.time + 5) * 60000);
  
  const departureDate = new Date();
  departureDate.setHours(7, 10, 0, 0);
  const leaveHomeTime = new Date(departureDate.getTime() - (leg1.time + 10) * 60000);

  const formatTime = (date) => date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

  // Helper for Schematic Map Colors
  const getSchematicColor = (modeId) => {
    if (modeId === 'uber' || modeId === 'drive_park') return 'stroke-orange-500';
    if (modeId === 'bus' || modeId === 'walk_train') return 'stroke-emerald-500';
    if (modeId === 'cycle') return 'stroke-blue-500';
    return 'stroke-slate-300';
  };

  // --- RENDER: SUMMARY VIEW (User Preference) ---
  if (view === 'summary') {
    return (
      <div className="flex flex-col h-screen bg-slate-50 font-sans text-slate-900">
        
        {/* --- TOP: SCHEMATIC VISUALIZATION --- */}
        <div className="h-1/3 bg-slate-200 relative overflow-hidden flex items-center justify-center">
          <div className="absolute inset-0 bg-slate-100 opacity-50" 
               style={{backgroundImage: 'radial-gradient(#cbd5e1 1px, transparent 1px)', backgroundSize: '20px 20px'}}>
          </div>
          
          <svg className="w-full max-w-md h-32 z-10" viewBox="0 0 400 120">
            <line x1="50" y1="60" x2="350" y2="60" className="stroke-slate-300" strokeWidth="4" strokeDasharray="4 4" />
            
            {/* Leg 1 */}
            <line x1="50" y1="60" x2="150" y2="60" className={`${getSchematicColor(leg1.id)} transition-colors duration-500`} strokeWidth="4" />
            
            {/* Leg 2 (Fixed) */}
            <line x1="150" y1="60" x2="250" y2="60" className="stroke-indigo-600" strokeWidth="6" />
            
            {/* Leg 3 */}
            <line x1="250" y1="60" x2="350" y2="60" className={`${getSchematicColor(leg3.id)} transition-colors duration-500`} strokeWidth="4" />

            <circle cx="50" cy="60" r="6" className="fill-white stroke-slate-500 stroke-2" />
            <text x="50" y="85" textAnchor="middle" className="text-[10px] fill-slate-500 font-bold uppercase">St Chads</text>
            
            <circle cx="150" cy="60" r="8" className="fill-white stroke-indigo-600 stroke-2" />
            <text x="150" y="40" textAnchor="middle" className="text-[10px] fill-indigo-600 font-bold uppercase">Leeds Stn</text>
            
            <circle cx="250" cy="60" r="8" className="fill-white stroke-indigo-600 stroke-2" />
            <text x="250" y="40" textAnchor="middle" className="text-[10px] fill-indigo-600 font-bold uppercase">Loughboro</text>

            <circle cx="350" cy="60" r="6" className="fill-slate-800 stroke-white stroke-2" />
            <text x="350" y="85" textAnchor="middle" className="text-[10px] fill-slate-800 font-bold uppercase">East Leake</text>
          </svg>

          <div className="absolute top-4 left-4 bg-white/90 backdrop-blur px-3 py-1 rounded-full text-xs font-semibold shadow-sm text-slate-600 border border-slate-200">
             St Chads View → East Leake
          </div>
          
          {/* Action to switch to MAP VIEW */}
          <button 
            onClick={() => setView('map')}
            className="absolute bottom-4 right-4 bg-white text-indigo-600 px-4 py-2 rounded-full text-sm font-bold shadow-lg flex items-center gap-2 hover:bg-indigo-50 transition-colors"
          >
            <MapIcon size={16} /> View Map
          </button>
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
                <tab.icon size={16} /> {tab.label}
              </button>
            ))}
          </div>

          {/* SUMMARY HEADER */}
          <div className="px-6 py-4 bg-white border-b border-slate-100 flex justify-between items-center">
            <div>
              <div className="text-3xl font-bold text-slate-900 flex items-center gap-2">
                £{totalCost.toFixed(2)}
                {totalCost < 35 && <span className="text-xs bg-emerald-100 text-emerald-700 px-2 py-1 rounded-full font-medium">In Policy</span>}
              </div>
              <div className="text-sm text-slate-500 mt-1 flex items-center gap-2">
                <Clock size={14} /> 
                {Math.floor(totalTime / 60)}h {totalTime % 60}m Total 
              </div>
            </div>
            
            <div className="text-right hidden sm:block">
              <div className="text-xs text-slate-400">vs Direct Drive</div>
              <div className="text-xs font-semibold text-slate-600 strike-through decoration-red-500">
                £{DIRECT_DRIVE.cost.toFixed(2)} • 1h 50m
              </div>
            </div>
          </div>

          {/* TIMELINE LIST */}
          <div className="flex-1 overflow-y-auto p-4 space-y-0">
            {/* Start */}
            <div className="flex gap-4 min-h-[40px]">
              <div className="w-16 text-right text-xs text-slate-500 font-mono py-1">{formatTime(leaveHomeTime)}</div>
              <div className="flex flex-col items-center">
                <div className="w-3 h-3 rounded-full bg-slate-400"></div>
                <div className="w-0.5 flex-1 bg-slate-200"></div>
              </div>
              <div className="pb-6"><div className="text-sm font-semibold text-slate-700">Start from St Chads View</div></div>
            </div>

            {/* Leg 1 */}
            <div className="flex gap-4 group">
              <div className="w-16 text-right text-xs text-slate-400 font-mono pt-4">{leg1.time} min</div>
              <div className="flex flex-col items-center"><div className="w-0.5 h-full bg-slate-200"></div></div>
              <div className="pb-8 flex-1">
                <button 
                  onClick={() => setShowSwap('first')}
                  className="w-full bg-white border border-slate-200 rounded-xl p-3 shadow-sm hover:border-blue-300 transition-all text-left flex items-center gap-3"
                >
                  <ModeIcon icon={leg1.icon} className="bg-blue-50 text-blue-600" />
                  <div className="flex-1">
                    <div className="flex justify-between">
                      <span className="font-semibold text-slate-800">{leg1.label}</span>
                      <span className="font-bold text-slate-900">£{leg1.cost.toFixed(2)}</span>
                    </div>
                    <div className="text-xs text-slate-500">{leg1.detail}</div>
                  </div>
                  <ChevronRight size={16} className="text-slate-400" />
                </button>
              </div>
            </div>

            {/* Main Leg */}
            <div className="flex gap-4">
              <div className="w-16 text-right text-xs text-slate-400 font-mono pt-4">1h 42m</div>
              <div className="flex flex-col items-center"><div className="w-1 h-full bg-indigo-500"></div></div>
              <div className="pb-8 flex-1">
                <div className="w-full bg-slate-50 border border-slate-100 rounded-xl p-3 flex items-center gap-3">
                  <ModeIcon icon={Train} className="bg-indigo-100 text-indigo-700" />
                  <div className="flex-1">
                    <div className="flex justify-between">
                      <span className="font-semibold text-slate-800">CrossCountry / EMR</span>
                      <span className="font-bold text-slate-900">£25.70</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Leg 3 */}
            <div className="flex gap-4 group">
              <div className="w-16 text-right text-xs text-slate-400 font-mono pt-4">{leg3.time} min</div>
              <div className="flex flex-col items-center"><div className="w-0.5 h-full bg-slate-200"></div></div>
              <div className="pb-8 flex-1">
                <button 
                  onClick={() => setShowSwap('last')}
                  className="w-full bg-white border border-slate-200 rounded-xl p-3 shadow-sm hover:border-blue-300 transition-all text-left flex items-center gap-3"
                >
                  <ModeIcon icon={leg3.icon} className="bg-blue-50 text-blue-600" />
                  <div className="flex-1">
                    <div className="flex justify-between">
                      <span className="font-semibold text-slate-800">{leg3.label}</span>
                      <span className="font-bold text-slate-900">£{leg3.cost.toFixed(2)}</span>
                    </div>
                    <div className="text-xs text-slate-500">{leg3.detail}</div>
                  </div>
                  <ChevronRight size={16} className="text-slate-400" />
                </button>
              </div>
            </div>

            {/* End */}
            <div className="flex gap-4 min-h-[40px]">
              <div className="w-16 text-right text-xs text-slate-500 font-mono py-1">{formatTime(destArrivalTime)}</div>
              <div className="flex flex-col items-center"><div className="w-3 h-3 rounded-full bg-slate-800"></div></div>
              <div><div className="text-sm font-semibold text-slate-700">Arrive East Leake</div></div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // --- RENDER: ADVANCED MAP VIEW ---
  // --- RENDER: ADVANCED MAP VIEW ---
  return (
    <div className="h-screen bg-slate-900 font-sans text-slate-900 flex flex-col overflow-hidden relative">
      
      {/* 1. MAP AREA */}
      <div className="absolute top-0 left-0 right-0 bottom-0 z-0 h-[60%]">
        <RealisticMap leg1={leg1} leg3={leg3} focusedSegment={showSwap} />
        
        {/* Top Controls */}
        <div className="absolute top-6 left-6 right-6 flex justify-between z-20">
          <button 
            onClick={() => setView('summary')}
            className="bg-white/90 backdrop-blur px-4 py-2 rounded-full shadow-lg hover:bg-white transition-colors flex items-center gap-2 text-sm font-bold text-slate-700"
          >
            <ChevronLeft size={16} /> Back to Summary
          </button>
        </div>
      </div>

      {/* 2. SLIDING SHEET */}
      <div className="absolute inset-x-0 bottom-0 h-[50vh] bg-white rounded-t-3xl shadow-[0_-10px_40px_rgba(0,0,0,0.2)] flex flex-col z-10 animate-in slide-in-from-bottom-24 duration-500">
        <div className="w-full flex justify-center pt-3 pb-1 cursor-grab">
          <div className="w-12 h-1.5 bg-slate-200 rounded-full"></div>
        </div>

        <div className="px-6 py-2 border-b border-slate-50 shrink-0 flex justify-between items-center">
           <div>
             <h2 className="text-lg font-bold text-slate-800">Route Map</h2>
             <p className="text-xs text-slate-400">Interactive Editing</p>
           </div>
           <div className="text-right">
             <div className="text-xl font-bold text-slate-900">£{totalCost.toFixed(2)}</div>
           </div>
        </div>

        <div className="flex-1 overflow-y-auto px-6 py-6 custom-scrollbar pb-24">
          <div className="relative pl-4 space-y-6">
            <div className="absolute left-[27px] top-4 bottom-4 w-1 bg-slate-100 rounded-full"></div>

            {/* Edit Leg 1 */}
            <div className="relative flex gap-6 group">
              <div className="flex flex-col items-center z-10 pt-1">
                <div className={`w-3 h-3 rounded-full border-2 bg-white ${leg1.id === 'uber' ? 'border-zinc-500' : 'border-emerald-500'}`}></div>
              </div>
              <button 
                onClick={() => setShowSwap('first')}
                className={`flex-1 text-left relative p-3 rounded-2xl border transition-all duration-300 shadow-sm ${leg1.bgColor} border-transparent`}
              >
                <div className="flex justify-between items-center">
                   <span className="font-bold text-sm text-slate-800">{leg1.label}</span>
                   <span className="text-[10px] font-bold text-blue-600 bg-white/50 px-2 py-0.5 rounded">CHANGE</span>
                </div>
              </button>
            </div>

            {/* Main Leg Info */}
            <div className="relative flex gap-6">
               <div className="flex flex-col items-center z-10 pt-1">
                <div className="w-4 h-4 rounded-full border-4 border-indigo-600 bg-white"></div>
              </div>
              <div className="flex-1 p-3 rounded-2xl border border-indigo-50 bg-white shadow-sm opacity-80">
                 <span className="font-bold text-sm text-slate-800">Train Leg (Fixed)</span>
              </div>
            </div>

            {/* Edit Leg 3 */}
            <div className="relative flex gap-6 group">
              <div className="flex flex-col items-center z-10 pt-1">
                 <div className={`w-3 h-3 rounded-full border-2 bg-white ${leg3.id === 'uber' ? 'border-zinc-500' : 'border-blue-500'}`}></div>
              </div>
              <button 
                onClick={() => setShowSwap('last')}
                className={`flex-1 text-left relative p-3 rounded-2xl border transition-all duration-300 shadow-sm ${leg3.bgColor} border-transparent`}
              >
                <div className="flex justify-between items-center">
                   <span className="font-bold text-sm text-slate-800">{leg3.label}</span>
                   <span className="text-[10px] font-bold text-blue-600 bg-white/50 px-2 py-0.5 rounded">CHANGE</span>
                </div>
              </button>
            </div>
          </div>
        </div>
        
        <div className="p-4 bg-white border-t border-slate-100 absolute bottom-0 w-full">
           <button className="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-3 px-4 rounded-xl shadow-lg transition-all flex items-center justify-center gap-2">
             Confirm & Book <Navigation size={18} />
           </button>
        </div>
      </div>

      <SwapModal 
        isOpen={showSwap === 'first'}
        onClose={() => setShowSwap(null)}
        title="Change Start (Leeds)"
        options={SEGMENT_OPTIONS.firstMile}
        onSelect={setLeg1}
        currentId={leg1.id}
      />
      <SwapModal 
        isOpen={showSwap === 'last'}
        onClose={() => setShowSwap(null)}
        title="Change End (Loughborough)"
        options={SEGMENT_OPTIONS.lastMile}
        onSelect={setLeg3}
        currentId={leg3.id}
      />
    </div>
  );
}

