import { Routes } from '@angular/router';

import { Home } from './home/home';
import { ProductList } from './product-list/product-list';
import { CartView } from './cart-view/cart-view';
import { cartViewGuardGuard } from './cart-view-guard-guard';
import { productListGuardGuard } from './product-list-guard-guard';

export const routes: Routes = [

    {
        path: '',
        component: Home
    },
    {
        path: 'products',
        component: ProductList,
        canDeactivate: [productListGuardGuard],
    },

    {
        path: 'products/:category',
        component: ProductList,
    },

    {
        path: 'cart',
        component: CartView,
        canActivate: [cartViewGuardGuard]
    },
    {
        path: '**',
        redirectTo: ''
    }

];
