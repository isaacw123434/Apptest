import { useState } from 'react';
import PropTypes from 'prop-types';

const ModeIcon = ({ mode }) => {
  // Component logic here
  return <div>{mode}</div>;
};

ModeIcon.propTypes = {
  mode: PropTypes.string.isRequired,
};

const SwapModal = ({ isOpen, onClose }) => {
  // Component logic here
  return (
    <div>
      {isOpen ? 'Modal is open' : 'Modal is closed'}
      <button onClick={onClose}>Close</button>
    </div>
  );
};

SwapModal.propTypes = {
  isOpen: PropTypes.bool.isRequired,
  onClose: PropTypes.func.isRequired,
};

const App = () => {
  const [isModalOpen, setIsModalOpen] = useState(false);

  return (
    <div>
      <h1>Journey Planner</h1>
      <ModeIcon mode="train" />
      <button onClick={() => setIsModalOpen(true)}>Open Modal</button>
      <SwapModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} />
    </div>
  );
};

export { ModeIcon, SwapModal };
export default App;
