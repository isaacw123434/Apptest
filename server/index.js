const express = require('express');
const cors = require('cors');
const {
  SEGMENT_OPTIONS,
  DIRECT_DRIVE,
  MOCK_PATH,
  getTop3Results
} = require('./journeyService');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

// GET /api/init
// Returns the initial data needed for the app
app.get('/api/init', (req, res) => {
  res.json({
    segmentOptions: SEGMENT_OPTIONS,
    directDrive: DIRECT_DRIVE,
    mockPath: MOCK_PATH
  });
});

// POST /api/search
// Accepts: { tab: 'smart'|'fastest'|'cheapest', selectedModes: { train: bool, ... } }
// Returns: Top 3 journey combinations
app.post('/api/search', (req, res) => {
  const { tab, selectedModes } = req.body;

  // Default values if not provided
  const searchTab = tab || 'smart';
  const modes = selectedModes || {
    train: true,
    bus: true,
    car: true,
    bike: true,
    taxi: true
  };

  const results = getTop3Results(searchTab, modes);
  res.json(results);
});

app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});
