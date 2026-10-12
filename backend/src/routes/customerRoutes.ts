import { Router } from 'express';
import { getCategories, getCategoryDetails, getAvailableProducts, getSellersForVariant, placeOrder, getCustomerProfile, getAddresses, addAddress, getOrderHistory } from '../controllers/customerController';

const router = Router();

router.get('/categories', getCategories);
router.get('/categories/:categoryId', getCategoryDetails);
router.get('/products', getAvailableProducts);
router.get('/master-variants/:variantId/sellers', getSellersForVariant);
router.get('/profile/:userId', getCustomerProfile);
router.get('/addresses/:userId', getAddresses);
router.post('/addresses/:userId', addAddress);
router.get('/orders/:userId', getOrderHistory);
router.post('/order', placeOrder);

export default router;
