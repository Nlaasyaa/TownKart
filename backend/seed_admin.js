"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
const db_1 = require("./src/config/db");
const crypto_1 = require("crypto");
function seedAdmin() {
    return __awaiter(this, void 0, void 0, function* () {
        try {
            const email = 'ops@townkart.in';
            const password = 'password123'; // As per screenshot mask
            const check = yield (0, db_1.query)('SELECT id FROM users WHERE email = ?', [email]);
            if (check.rows.length > 0) {
                console.log('Admin already exists.');
                process.exit(0);
            }
            const userId = (0, crypto_1.randomUUID)();
            yield (0, db_1.query)(`INSERT INTO users (id, email, phone, password_hash, role, is_verified) 
       VALUES (?, ?, ?, ?, 'ADMIN', TRUE)`, [userId, email, '0000000000', password]);
            const adminId = (0, crypto_1.randomUUID)();
            yield (0, db_1.query)(`INSERT INTO admins (id, user_id, full_name, designation) VALUES (?, ?, ?, ?)`, [adminId, userId, 'Aditi Rao', 'Platform Admin']);
            console.log('Admin seeded successfully! Email: ops@townkart.in, Password: password123');
            process.exit(0);
        }
        catch (err) {
            console.error('Failed to seed admin', err);
            process.exit(1);
        }
    });
}
seedAdmin();
