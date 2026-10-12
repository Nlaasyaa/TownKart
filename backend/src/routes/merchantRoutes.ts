import { Router } from 'express';
import { getDashboard, getProducts, getOrders, getSettings, getCategories, toggleCategory, getSubcategories, getAvailableMasterProducts, addProduct, updateProduct, deleteProduct, toggleProductStatus, updateOrderStatus } from '../controllers/merchantController';

const router = Router();

router.get('/dashboard/:userId', getDashboard);
router.get('/products/:userId', getProducts);
router.get('/orders/:userId', getOrders);
router.get('/settings/:userId', getSettings);
router.get('/categories/:userId', getCategories);
router.patch('/categories/:userId/:categoryId/toggle', toggleCategory);
router.get('/subcategories/:userId', getSubcategories);
router.get('/master-products/:userId/:subcategoryId', getAvailableMasterProducts);
router.post('/products/:userId', addProduct);
router.put('/products/:userId/:productId', updateProduct);
router.delete('/products/:userId/:productId', deleteProduct);
router.patch('/products/:userId/:productId/status', toggleProductStatus);
router.patch('/orders/:userId/:merchantOrderId/status', updateOrderStatus);

export default router;
