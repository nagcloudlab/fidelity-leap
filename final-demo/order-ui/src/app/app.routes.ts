import { Routes } from '@angular/router';
import { ProductList } from './product-list/product-list';
import { OrderForm } from './order-form/order-form';
import { OrderHistory } from './order-history/order-history';
import { AnalyticsDashboard } from './analytics-dashboard/analytics-dashboard';

export const routes: Routes = [
  { path: '', redirectTo: 'products', pathMatch: 'full' },
  { path: 'products', component: ProductList },
  { path: 'order', component: OrderForm },
  { path: 'orders', component: OrderHistory },
  { path: 'analytics', component: AnalyticsDashboard },
  { path: '**', redirectTo: 'products' },
];
