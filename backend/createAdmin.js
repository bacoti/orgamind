// backend/createAdmin.js
const pool = require('./src/config/database');
const { hashPassword } = require('./src/utils/passwordUtils');

async function createAdmin() {
    try {
        const name = "Super Admin";
        const email = "admin@orgamind.com";
        const plainPassword = "password123"; 
        const role = "admin"; 

        // 1. Cek diam-diam, kalau sudah ada, langsung berhenti (return)
        const [existingUser] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);
        if (existingUser.length > 0) {
            // Admin sudah ada, tidak perlu melakukan apa-apa
            return; 
        }

        console.log("⚙️  Menginisialisasi Akun Admin...");
        const hashedPassword = await hashPassword(plainPassword);

        const sql = `
            INSERT INTO users (name, email, password, role, created_at, updated_at) 
            VALUES (?, ?, ?, ?, NOW(), NOW())
        `;
        
        await pool.query(sql, [name, email, hashedPassword, role]);

        console.log("✅  ADMIN OTOMATIS DIBUAT: admin@orgamind.com / password123");

    } catch (error) {
        console.error("❌ Gagal membuat admin otomatis:", error.message);
        // Jangan pakai process.exit(), biar server tetap jalan walau error
    }
}

module.exports = createAdmin; // Ekspor fungsi ini agar bisa dipanggil file lain