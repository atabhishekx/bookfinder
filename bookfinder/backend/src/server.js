require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');
const bookRoutes = require('./routes/books');
const healthRoutes = require('./routes/health');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.use('/api/health', healthRoutes);
app.use('/api/books', bookRoutes);

app.get('/logo.svg', (req, res) => {
  res.sendFile(path.join(__dirname, 'logo.svg'));
});

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

app.listen(PORT, () => {
  console.log(`BookFinder API running on http://localhost:${PORT}`);
});

module.exports = app;