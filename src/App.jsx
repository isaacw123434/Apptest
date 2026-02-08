import { useState } from 'react';
import PropTypes from 'prop-types';
import { Train, Bus, Car, Bike, Footprints } from 'lucide-react';

const ModeIcon = ({ mode }) => {
  const icons = {
    train: Train,
    bus: Bus,
    car: Car,
    bike: Bike,
    walk: Footprints,
  };

  const Icon = icons[mode] || Train;

  return (
    <div className="p-4 bg-gray-100 rounded-full inline-block">
      <Icon size={48} className="text-blue-600" />
    </div>
  );
};

ModeIcon.propTypes = {
  mode: PropTypes.oneOf(['train', 'bus', 'car', 'bike', 'walk']).isRequired,
};

const SwapModal = ({ isOpen, onClose, onModeSelect }) => {
  if (!isOpen) return null;

  const modes = [
    { id: 'train', label: 'Train', icon: Train },
    { id: 'bus', label: 'Bus', icon: Bus },
    { id: 'car', label: 'Car', icon: Car },
    { id: 'bike', label: 'Bike', icon: Bike },
    { id: 'walk', label: 'Walk', icon: Footprints },
  ];

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg p-6 w-full max-w-sm shadow-xl">
        <h2 className="text-xl font-bold mb-4">Select Mode</h2>
        <div className="grid grid-cols-3 gap-4 mb-6">
          {modes.map((m) => (
            <button
              key={m.id}
              onClick={() => {
                onModeSelect(m.id);
                onClose();
              }}
              className="flex flex-col items-center p-3 rounded hover:bg-gray-100 transition-colors"
            >
              <m.icon className="mb-2" />
              <span className="text-sm">{m.label}</span>
            </button>
          ))}
        </div>
        <button
          onClick={onClose}
          className="w-full py-2 bg-gray-200 rounded hover:bg-gray-300 transition-colors font-medium"
        >
          Close
        </button>
      </div>
    </div>
  );
};

SwapModal.propTypes = {
  isOpen: PropTypes.bool.isRequired,
  onClose: PropTypes.func.isRequired,
  onModeSelect: PropTypes.func.isRequired,
};

const App = () => {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [mode, setMode] = useState('train');

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col items-center pt-20">
      <h1 className="text-3xl font-bold text-gray-800 mb-8">Journey Planner</h1>

      <div className="bg-white p-8 rounded-xl shadow-lg flex flex-col items-center gap-6 w-full max-w-md">
        <div className="text-center">
          <p className="text-gray-500 mb-4 font-medium uppercase tracking-wide text-sm">Current Mode</p>
          <ModeIcon mode={mode} />
          <p className="mt-2 text-lg font-semibold capitalize">{mode}</p>
        </div>

        <button
          onClick={() => setIsModalOpen(true)}
          className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-medium shadow-sm hover:shadow-md"
        >
          Swap Mode
        </button>
      </div>

      <SwapModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onModeSelect={setMode}
      />
    </div>
  );
};

export { ModeIcon, SwapModal };
export default App;
