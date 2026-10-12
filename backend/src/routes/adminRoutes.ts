import { Router } from 'express';
import { getDashboard, getCustomers, getMerchants, getProducts, getProfile, updateMerchantStatus } from '../controllers/adminController';

const router = Router();

router.get('/dashboard/:userId', getDashboard);
router.get('/profile/:userId', getProfile);
router.get('/customers/:userId', getCustomers);
router.get('/merchants/:userId', getMerchants);
router.put('/merchants/:merchantId/status', updateMerchantStatus);
router.get('/products/:userId', getProducts);

export default router;
