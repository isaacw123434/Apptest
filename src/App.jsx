import React from 'react';
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
  return <div>{isOpen ? 'Modal is open' : 'Modal is closed'}</div>;
};

SwapModal.propTypes = {
  isOpen: PropTypes.bool.isRequired,
  onClose: PropTypes.func.isRequired,
};

export { ModeIcon, SwapModal };