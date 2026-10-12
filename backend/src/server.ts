import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import authRoutes from './routes/authRoutes';
import merchantRoutes from './routes/merchantRoutes';
import adminRoutes from './routes/adminRoutes';
import customerRoutes from './routes/customerRoutes';
import pool from './config/db';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/merchant', merchantRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/customer', customerRoutes);

app.get('/', (req, res) => {
  res.send('TownKart API is running');
});

// Test DB Connection before starting server
pool.getConnection()
  .then((client) => {
    console.log('Successfully connected to Database');
    client.release();
    app.listen(PORT, () => {
      console.log(`Server is running on port ${PORT}`);
    });
  })
  .catch((err) => {
    console.error('Failed to connect to the database', err);
    process.exit(1);
  });

