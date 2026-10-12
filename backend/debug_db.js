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
function run() {
    return __awaiter(this, void 0, void 0, function* () {
        try {
            const users = yield (0, db_1.query)('SELECT id, role, email, phone FROM users');
            console.log('--- USERS ---');
            console.log(users.rows);
            const merchants = yield (0, db_1.query)('SELECT id, user_id, owner_name FROM merchants');
            console.log('--- MERCHANTS ---');
            console.log(merchants.rows);
            const shops = yield (0, db_1.query)('SELECT id, merchant_id, shop_name FROM shops');
            console.log('--- SHOPS ---');
            console.log(shops.rows);
            process.exit(0);
        }
        catch (err) {
            console.error(err);
            process.exit(1);
        }
    });
}
run();
