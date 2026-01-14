const mysql = require('mysql2/promise');
require('dotenv').config();

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'orgamind_db',
  port: process.env.DB_PORT || 3306,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  // --- PERBAIKAN TANGGAL ---
  dateStrings: true, // Agar tanggal dibaca apa adanya (String), tidak dikonversi ke UTC
  timezone: '+07:00' // Memaksa koneksi menggunakan zona waktu WIB (Opsional tapi bagus)
});

module.exports = pool;