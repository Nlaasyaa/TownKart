import { Router } from 'express';
import { registerCustomer, registerMerchant, loginUser, sendOtp } from '../controllers/authController';

const router = Router();

router.post('/register-customer', registerCustomer);
router.post('/register-merchant', registerMerchant);
router.post('/login', loginUser);
router.post('/send-otp', sendOtp);

export default router;
